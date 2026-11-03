/// One panic-alert episode that the bracelet detected and the user lived
/// through. Built once on the falling edge of an alert, persisted locally
/// to SharedPreferences, and pushed to the Supabase `alerts` table.
///
/// `synced` tracks whether this record has been successfully copied to
/// the cloud. Records start unsynced and flip to true once the Supabase
/// insert returns successfully — that way an offline alert can be queued
/// and pushed up the next time the device has a connection.
class AlertRecord {
  final String id; // local-side unique id, mirrors the Supabase row id
  final DateTime startTime;
  final DateTime endTime;
  final double peakBpm;
  final double peakGsr;
  final int durationSeconds;
  bool synced;

  AlertRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.peakBpm,
    required this.peakGsr,
    required this.durationSeconds,
    this.synced = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': startTime.toIso8601String(),
        'end': endTime.toIso8601String(),
        'peakBpm': peakBpm,
        'peakGsr': peakGsr,
        'duration': durationSeconds,
        'synced': synced,
      };

  factory AlertRecord.fromJson(Map<String, dynamic> json) {
    return AlertRecord(
      // Older records from before id was added get a generated one.
      id: (json['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      startTime: DateTime.parse(json['start'] as String),
      endTime: DateTime.parse(json['end'] as String),
      peakBpm: (json['peakBpm'] as num).toDouble(),
      peakGsr: (json['peakGsr'] as num).toDouble(),
      durationSeconds: json['duration'] as int,
      synced: (json['synced'] as bool?) ?? false,
    );
  }
}
