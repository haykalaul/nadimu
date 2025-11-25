import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  
  var healthSummary = ''.obs;
  var summaryDescription = ''.obs;
  var analysisDateRange = 'Analysis based on data from the last 7 days.'.obs;

  var riskAssessments = <RiskAssessment>[].obs;
  var activitySuggestions = <ActivitySuggestion>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with default/empty state
    _initializeDefaultData();
  }

  void _initializeDefaultData() {
    healthSummary.value = 'Your Health Summary';
    summaryDescription.value = 'Based on your recent measurements, your cardiovascular health appears to be stable. Your heart rate and SpO2 levels are within the normal range.';
    
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
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real app, this would fetch data from an API
    // For now, we'll use the default data
    hasAnalysis.value = true;
    isLoading.value = false;
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
}

