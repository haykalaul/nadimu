import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nadimu/services/history_service.dart';
import 'package:nadimu/models/measurement_history.dart';
import 'package:nadimu/services/mqtt_service.dart';

enum RiskLevel { low, medium, high }

class RiskAssessment {
  final String title;
  final String description;
  final RiskLevel level;
  final String icon;

  RiskAssessment({
    required this.title,
    required this.description,
    required this.level,
    required this.icon,
  });
}

class ActivitySuggestion {
  final String title;
  final String description;
  final String icon;

  ActivitySuggestion({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class AnalysisController extends GetxController {
  var isLoading = false.obs;
  var hasAnalysis = false.obs;
  final HistoryService _historyService = HistoryService();
  var analysisDays = 7.obs;
  final MqttService _mqttService = MqttService();
  var isConnected = false.obs;
  void Function(bool)? _connListener;

  var healthSummary = ''.obs;
  var summaryDescription = ''.obs;
  var analysisDateRange = 'Analysis based on data from the last 7 days.'.obs;

  var riskAssessments = <RiskAssessment>[].obs;
  var activitySuggestions = <ActivitySuggestion>[].obs;
  static const String _apiKey = 'AIzaSyCGpJKmA5tI9X8OiuRadA_w4YUsXSw8bCc';

  @override
  void onInit() {
    super.onInit();
    // Initialize with default/empty state
    _initializeDefaultData();
    isConnected.value = _mqttService.isConnected;
    _connListener = (c) => isConnected.value = c;
    _mqttService.addConnectionListener(_connListener!);
  }

  void _initializeDefaultData() {
    healthSummary.value = 'Your Health Summary';
    summaryDescription.value =
        'Based on your recent measurements, your cardiovascular health appears to be stable. Your heart rate and SpO2 levels are within the normal range.';
    analysisDateRange.value =
        'Analysis based on data from the last ${analysisDays.value} days.';

    riskAssessments.value = [
      RiskAssessment(
        title: 'Tachycardia Risk',
        description: 'Your risk of an abnormally high heart rate is low.',
        level: RiskLevel.low,
        icon: 'monitor_heart',
      ),
      RiskAssessment(
        title: 'Hypoxia Risk',
        description: 'Your risk of low blood oxygen levels is low.',
        level: RiskLevel.low,
        icon: 'air',
      ),
    ];

    activitySuggestions.value = [
      ActivitySuggestion(
        title: 'Brisk Walk',
        description: 'Try a 15-minute brisk walk to improve circulation.',
        icon: 'directions_walk',
      ),
      ActivitySuggestion(
        title: 'Deep Breathing',
        description: 'Practice 5 minutes of deep breathing to lower stress.',
        icon: 'self_improvement',
      ),
    ];
  }

  Future<void> analyzeHealth() async {
    isLoading.value = true;
    try {
      if (_apiKey.isEmpty) {
        healthSummary.value = 'Unable to analyze';
        summaryDescription.value =
            'Missing Gemini API key. Provide it via --dart-define=GEMINI_API_KEY.';
        analysisDateRange.value =
            'Analysis based on data from the last ${analysisDays.value} days.';
        hasAnalysis.value = false;
        return;
      }

      final days = analysisDays.value;
      final measurements = await _historyService.getRecentHistory(days);

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final inputData = _buildInputData(measurements);
      final prompt = _buildPrompt(inputData, days);
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        hasAnalysis.value = false;
        return;
      }

      final Map<String, dynamic> data =
          json.decode(text) as Map<String, dynamic>;

      healthSummary.value =
          (data['summary'] as String?) ?? 'Your Health Summary';
      summaryDescription.value = (data['description'] as String?) ?? '';
      analysisDateRange.value =
          (data['analysis_date_range'] as String?) ??
          'Analysis based on data from the last $days days.';

      final risks = (data['risk_assessments'] as List?) ?? [];
      riskAssessments.value = risks.map((e) {
        final m = e as Map<String, dynamic>;
        final levelStr = (m['level'] as String?) ?? 'medium';
        return RiskAssessment(
          title: (m['title'] as String?) ?? '',
          description: (m['description'] as String?) ?? '',
          level: _riskLevelFromString(levelStr),
          icon: (m['icon'] as String?) ?? 'info',
        );
      }).toList();

      final suggestions = (data['activity_suggestions'] as List?) ?? [];
      activitySuggestions.value = suggestions.map((e) {
        final m = e as Map<String, dynamic>;
        return ActivitySuggestion(
          title: (m['title'] as String?) ?? '',
          description: (m['description'] as String?) ?? '',
          icon: (m['icon'] as String?) ?? 'directions_walk',
        );
      }).toList();

      hasAnalysis.value = true;
    } catch (e) {
      healthSummary.value = 'Your Health Summary';
      summaryDescription.value =
          'Unable to generate AI analysis. Using default data.';
      analysisDateRange.value =
          'Analysis based on data from the last ${analysisDays.value} days.';
      hasAnalysis.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  String getRiskLevelText(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
    }
  }

  Color getRiskLevelColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return const Color(0xFF10B981); // green-500
      case RiskLevel.medium:
        return const Color(0xFFF59E0B); // amber-500
      case RiskLevel.high:
        return const Color(0xFFEF4444); // red-500
    }
  }

  RiskLevel _riskLevelFromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'high':
        return RiskLevel.high;
      case 'medium':
      default:
        return RiskLevel.medium;
    }
  }

  String _buildPrompt(Map<String, dynamic> inputData, int days) {
    final allowedIcons = [
      'monitor_heart',
      'air',
      'directions_walk',
      'self_improvement',
    ];
    return 'You are a health analysis assistant. Analyze the following summarized measurement history for the past ' +
        '$days days and produce a cardiovascular risk assessment and activity suggestions tailored to the patterns observed. ' +
        'Use risk levels strictly from [low, medium, high]. Choose icons only from ${allowedIcons.join(', ')}. ' +
        'Return a pure JSON object with keys: summary, description, analysis_date_range, risk_assessments, activity_suggestions. ' +
        'risk_assessments is an array of objects: {title, description, level, icon}. ' +
        'activity_suggestions is an array of objects: {title, description, icon}. ' +
        'Do not include markdown or code fences. Input data: ' +
        json.encode(inputData);
  }

  Map<String, dynamic> _buildInputData(List<MeasurementHistory> measurements) {
    if (measurements.isEmpty) {
      return {'has_data': false};
    }
    final hrValues = measurements.map((m) => m.heartRate).toList();
    final spo2Values = measurements.map((m) => m.spo2).toList();
    final avgHr = hrValues.isEmpty
        ? 0
        : (hrValues.reduce((a, b) => a + b) / hrValues.length);
    final avgSpo2 = spo2Values.isEmpty
        ? 0
        : (spo2Values.reduce((a, b) => a + b) / spo2Values.length);
    final minHr = hrValues.isEmpty
        ? 0
        : hrValues.reduce((a, b) => a < b ? a : b);
    final maxHr = hrValues.isEmpty
        ? 0
        : hrValues.reduce((a, b) => a > b ? a : b);
    final minSpo2 = spo2Values.isEmpty
        ? 0
        : spo2Values.reduce((a, b) => a < b ? a : b);
    final maxSpo2 = spo2Values.isEmpty
        ? 0
        : spo2Values.reduce((a, b) => a > b ? a : b);

    final statusCounts = <String, int>{};
    for (final m in measurements) {
      final s = m.status.toLowerCase();
      if (s.contains('error') ||
          s.contains('danger') ||
          s.contains('critical')) {
        statusCounts['danger'] = (statusCounts['danger'] ?? 0) + 1;
      } else if (s.contains('alert') || s.contains('low')) {
        statusCounts['alert'] = (statusCounts['alert'] ?? 0) + 1;
      } else {
        statusCounts['normal'] = (statusCounts['normal'] ?? 0) + 1;
      }
    }

    final activities = measurements.map((m) => m.activityMode).toSet().toList();

    return {
      'has_data': true,
      'count': measurements.length,
      'avg_heart_rate': avgHr.round(),
      'avg_spo2': avgSpo2.round(),
      'min_heart_rate': minHr,
      'max_heart_rate': maxHr,
      'min_spo2': minSpo2,
      'max_spo2': maxSpo2,
      'status_counts': statusCounts,
      'activities': activities,
      'samples': measurements
          .take(10)
          .map(
            (m) => {
              'timestamp': m.timestamp.toIso8601String(),
              'heartRate': m.heartRate,
              'spo2': m.spo2,
              'quality': m.quality,
              'status': m.status,
              'activityMode': m.activityMode,
              'duration': m.duration,
            },
          )
          .toList(),
    };
  }

  @override
  void onClose() {
    if (_connListener != null) {
      _mqttService.removeConnectionListener(_connListener!);
    }
    super.onClose();
  }
}
