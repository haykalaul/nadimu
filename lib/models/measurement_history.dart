class MeasurementHistory {
  final String id;
  final DateTime timestamp;
  final int heartRate;
  final int spo2;
  final int quality;
  final String status;
  final String activityMode;
  final List<double> heartRateData;
  final int duration; // in seconds

  MeasurementHistory({
    required this.id,
    required this.timestamp,
    required this.heartRate,
    required this.spo2,
    required this.quality,
    required this.status,
    required this.activityMode,
    required this.heartRateData,
    required this.duration,
  });

  factory MeasurementHistory.fromJson(Map<String, dynamic> json) {
    return MeasurementHistory(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      heartRate: json['heartRate'] as int,
      spo2: json['spo2'] as int,
      quality: json['quality'] as int,
      status: json['status'] as String,
      activityMode: json['activityMode'] as String,
      heartRateData: (json['heartRateData'] as List).map((e) => (e as num).toDouble()).toList(),
      duration: json['duration'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'heartRate': heartRate,
      'spo2': spo2,
      'quality': quality,
      'status': status,
      'activityMode': activityMode,
      'heartRateData': heartRateData,
      'duration': duration,
    };
  }

  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final measurementDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (measurementDate == today) {
      return 'Today';
    } else if (measurementDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[timestamp.weekday - 1];
    }
  }

  String get formattedDate {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year}';
  }

  String get formattedTime {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get statusLabel {
    if (status.toLowerCase().contains('normal') || 
        status.toLowerCase().contains('complete') ||
        status.toLowerCase().contains('ready')) {
      return 'Normal';
    } else if (status.toLowerCase().contains('alert') ||
               status.toLowerCase().contains('low')) {
      return 'Alert';
    } else if (status.toLowerCase().contains('error') ||
               status.toLowerCase().contains('danger') ||
               status.toLowerCase().contains('critical')) {
      return 'Danger';
    }
    return 'Normal';
  }
}

