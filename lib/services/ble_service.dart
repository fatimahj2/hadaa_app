import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hadaa_app/models/alert_record.dart';
import 'package:hadaa_app/services/history_service.dart';
import 'package:hadaa_app/services/user_settings.dart';
import 'package:hadaa_app/utils/notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class BleBraceletService extends ChangeNotifier {
  final List<BluetoothDevice> devices = [];
  BluetoothDevice? device;
  BluetoothCharacteristic? notifyCharacteristic;
  BluetoothCharacteristic? commandCharacteristic;

  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<List<int>>? notifySubscription;
  StreamSubscription<BluetoothConnectionState>? connectionStateSubscription;

  bool scanning = false;
  bool connected = false;
  bool alert = false;

  String? connectedDeviceId;
  String lastRawData = '';

  // Latest sensor values
  double? bpm;
  double? gsr;
  double? motion;
  int? battery;
  bool calibrating = false;
  // Locked GSR baseline value reported by the bracelet — used to label
  // the current GSR reading as "relaxed" or "stressed" in the home UI.
  // 0 while the bracelet is still learning the baseline.
  double? gsrBaseline;

  // Last time we received any BLE notification — used by the home screen
  // to distinguish "connected and streaming" from "connected but stale".
  DateTime? lastDataAt;

  // Rolling history for charts (last 60 samples each)
  static const int _historyLength = 60;
  final List<double> bpmHistory = [];
  final List<double> gsrHistory = [];

  // Alert episode tracking — populated on rising edge, used on falling edge
  // to build a HistoryService record, and exposed to AlertScreen for the
  // live elapsed-time counter.
  DateTime? alertStartedAt;
  double peakBpmInAlert = 0;
  double peakGsrInAlert = 0;

  final Guid serviceUuid = Guid("12345678-1234-1234-1234-1234567890ab");
  final Guid characteristicUuid =
      Guid("abcdefab-1234-5678-1234-abcdefabcdef");
  // Write characteristic for app→bracelet commands (CALIBRATE, VIBRATE...).
  final Guid commandUuid =
      Guid("abcdefab-1234-5678-1234-abcdefabcdf0");

  Future<void> init() async {
    await requestPermissions();
    await requestNotificationPermission();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.notification,
    ].request();
  }

  Future<void> startScan() async {
    devices.clear();
    scanning = true;
    notifyListeners();

    await FlutterBluePlus.stopScan();
    await scanSubscription?.cancel();

    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final d = r.device;
        final exists = devices.any((e) => e.remoteId == d.remoteId);
        if (!exists) {
          devices.add(d);
        }
      }
      notifyListeners();
    });

    // Bracelet name comes from user settings — defaults to 'Hadaa_Bracelet'
    // but can be changed in the settings screen.
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
      withNames: [userSettings.braceletName],
    );

    await Future.delayed(const Duration(seconds: 5));
    scanning = false;
    notifyListeners();
  }

  Future<void> connectToDevice(BluetoothDevice d) async {
    try {
      await FlutterBluePlus.stopScan();
      await notifySubscription?.cancel();
      await connectionStateSubscription?.cancel();

      if (device != null) {
        await device!.disconnect();
      }

      device = d;
      connectedDeviceId = d.remoteId.str;
      notifyListeners();

      await d.connect(timeout: const Duration(seconds: 10));

      // Request a larger MTU than the 23-byte BLE default. Without this,
      // the bracelet's notify payload (~50 bytes including all fields)
      // gets truncated to 20 bytes and only BPM + part of GSR survive,
      // which is why MOTION/BAT/CALIB silently disappear. 247 is the
      // max the BLE spec allows; the actual negotiated value may be
      // lower depending on what the phone supports, and that's fine.
      try {
        await d.requestMtu(247);
      } catch (_) {
        // Some peripherals/centrals don't support MTU negotiation —
        // we still try to connect with the default. The status line
        // will be truncated but BPM and GSR will at least flow.
      }

      connectionStateSubscription = d.connectionState.listen((state) {
        connected = state == BluetoothConnectionState.connected;
        if (!connected) {
          notifyCharacteristic = null;
          alert = false;
        }
        notifyListeners();
      });

      connected = true;
      notifyListeners();

      final services = await d.discoverServices();
      for (final service in services) {
        if (service.uuid == serviceUuid) {
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid == characteristicUuid) {
              notifyCharacteristic = characteristic;
              await characteristic.setNotifyValue(true);

              await notifySubscription?.cancel();
              notifySubscription =
                  characteristic.lastValueStream.listen((value) {
                final raw = utf8.decode(value, allowMalformed: true).trim();
                if (raw.isNotEmpty) {
                  lastRawData = raw;
                  _parseIncomingData(raw);
                  notifyListeners();
                }
              });
            } else if (characteristic.uuid == commandUuid) {
              commandCharacteristic = characteristic;
            }
          }
        }
      }
    } catch (_) {
      connected = false;
      connectedDeviceId = null;
      device = null;
      notifyCharacteristic = null;
      commandCharacteristic = null;
      notifyListeners();
    }
  }

  /// Write a command string to the bracelet's command characteristic.
  /// Returns false if no command characteristic was discovered, e.g. when
  /// the bracelet isn't connected or it's an old firmware without it.
  Future<bool> sendCommand(String command) async {
    final c = commandCharacteristic;
    if (c == null) return false;
    try {
      // withoutResponse is faster and matches the firmware's
      // CHR_PROPS_WRITE_WO_RESP capability.
      await c.write(utf8.encode(command), withoutResponse: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _parseIncomingData(String raw) {
    bool? newAlert;
    lastDataAt = DateTime.now();

    final parts = raw.split(',');
    for (final item in parts) {
      final pair = item.split(':');
      if (pair.length != 2) continue;

      final key = pair[0].trim().toUpperCase();
      final value = pair[1].trim();

      if (key == 'BPM') {
        bpm = double.tryParse(value);
      } else if (key == 'GSR') {
        gsr = double.tryParse(value);
      } else if (key == 'MOTION') {
        motion = double.tryParse(value);
      } else if (key == 'BAT') {
        battery = int.tryParse(value);
      } else if (key == 'CALIB') {
        calibrating = value == '1';
      } else if (key == 'GBASE') {
        final parsed = double.tryParse(value);
        // Bracelet sends 0 while still learning — keep our value null in
        // that case so the home screen knows to hide the relaxed/stressed
        // label until calibration completes.
        gsrBaseline = (parsed != null && parsed > 0) ? parsed : null;
      } else if (key == 'ALERT') {
        newAlert = value == '1';
      }
    }

    // Maintain rolling history for charts
    if (bpm != null) {
      bpmHistory.add(bpm!);
      if (bpmHistory.length > _historyLength) bpmHistory.removeAt(0);
    }
    if (gsr != null) {
      gsrHistory.add(gsr!);
      if (gsrHistory.length > _historyLength) gsrHistory.removeAt(0);
    }

    // Apply alert state transitions and emit history records
    if (newAlert != null) {
      if (newAlert && !alert) {
        alertStartedAt = DateTime.now();
        peakBpmInAlert = bpm ?? 0;
        peakGsrInAlert = gsr ?? 0;
        showAlertNotification();
      } else if (!newAlert && alert && alertStartedAt != null) {
        final now = DateTime.now();
        final record = AlertRecord(
          id: now.microsecondsSinceEpoch.toString(),
          startTime: alertStartedAt!,
          endTime: now,
          peakBpm: peakBpmInAlert,
          peakGsr: peakGsrInAlert,
          durationSeconds: now.difference(alertStartedAt!).inSeconds,
        );
        historyService.add(record);
        alertStartedAt = null;
      }
      alert = newAlert;
    }

    if (alert) {
      if (bpm != null && bpm! > peakBpmInAlert) peakBpmInAlert = bpm!;
      if (gsr != null && gsr! > peakGsrInAlert) peakGsrInAlert = gsr!;
    }
  }

  Future<void> disconnect() async {
    await notifySubscription?.cancel();
    await connectionStateSubscription?.cancel();
    await device?.disconnect();

    connected = false;
    connectedDeviceId = null;
    device = null;
    notifyCharacteristic = null;
    commandCharacteristic = null;
    alert = false;

    notifyListeners();
  }

  Future<void> disposeService() async {
    await scanSubscription?.cancel();
    await notifySubscription?.cancel();
    await connectionStateSubscription?.cancel();
    await device?.disconnect();
  }
}

/// Global single instance — used by every screen so they don't have to
/// pass it around as a constructor parameter, and so AppShell can read
/// the battery value to display in its header.
final BleBraceletService bleService = BleBraceletService();
