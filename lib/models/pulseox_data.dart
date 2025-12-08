class PulseOxData {
  final int heartrate;
  final int spo2;
  final int quality;
  final int timestamp;

  PulseOxData({
    required this.heartrate,
    required this.spo2,
    required this.quality,
    required this.timestamp,
  });

  factory PulseOxData.fromJson(Map<String, dynamic> json) {
    return PulseOxData(
      heartrate: json['heartrate'] as int? ?? 0,
      spo2: json['spo2'] as int? ?? 0,
      quality: json['quality'] as int? ?? 0,
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heartrate': heartrate,
      'spo2': spo2,
      'quality': quality,
      'timestamp': timestamp,
    };
  }
}

