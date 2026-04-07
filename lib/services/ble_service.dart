import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hadaa_app/utils/notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class BleBraceletService extends ChangeNotifier {
  final List<BluetoothDevice> devices = [];
  BluetoothDevice? device;
  BluetoothCharacteristic? notifyCharacteristic;

  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<List<int>>? notifySubscription;
  StreamSubscription<BluetoothConnectionState>? connectionStateSubscription;

  bool scanning = false;
  bool connected = false;
  bool alert = false;

  String? connectedDeviceId;
  String lastRawData = '';

  double? bpm;
  double? gsr;
  double? motion;

  final Guid serviceUuid = Guid("12345678-1234-1234-1234-1234567890ab");
  final Guid characteristicUuid = Guid("abcdefab-1234-5678-1234-abcdefabcdef");

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

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
      withNames: const ['Hadaa_Bracelet'],
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
              notifySubscription = characteristic.lastValueStream.listen((
                value,
              ) {
                final raw = utf8.decode(value, allowMalformed: true).trim();
                if (raw.isNotEmpty) {
                  lastRawData = raw;
                  _parseIncomingData(raw);
                  notifyListeners();
                }
              });
            }
          }
        }
      }
    } catch (_) {
      connected = false;
      connectedDeviceId = null;
      device = null;
      notifyCharacteristic = null;
      notifyListeners();
    }
  }

  void _parseIncomingData(String raw) {
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
      } else if (key == 'ALERT') {
        final newAlert = value == '1';
        if (newAlert && !alert) {
          showAlertNotification();
        }
        alert = newAlert;
      }
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
