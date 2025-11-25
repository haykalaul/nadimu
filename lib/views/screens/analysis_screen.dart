import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nadimu/controllers/analysis_controller.dart';
import 'package:nadimu/themes/app_theme.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Register controller if not already registered
    if (!Get.isRegistered<AnalysisController>()) {
      Get.put(AnalysisController());
    }
    final controller = Get.find<AnalysisController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildAppBar(context, isDark),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // Analyze Button
                    _buildAnalyzeButton(context, controller, isDark),
                    const SizedBox(height: 24),
                    // Summary Card
                    Obx(() => _buildSummaryCard(controller, isDark)),
                    const SizedBox(height: 24),
                    // Risk Assessment Section
                    _buildRiskAssessmentSection(controller, isDark),
                    const SizedBox(height: 24),
                    // Activity Suggestions Section
                    _buildActivitySuggestionsSection(controller, isDark),
                    const SizedBox(height: 16),
                    // Disclaimer
                    _buildDisclaimer(isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            onPressed: () => Get.back(),
          ),
          Expanded(
            child: Text(
              'AI Health Analysis',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                letterSpacing: -0.015,
              ),
            ),
          ),
          const SizedBox(width: 48), // Spacer for centering
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton(BuildContext context, AnalysisController controller, bool isDark) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : () async {
                  await controller.analyzeHealth();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Your health analysis has been generated.'),
                        backgroundColor: AppTheme.primary,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.auto_awesome, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Analyze My Health',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AnalysisController controller, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Background
          Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary.withOpacity(0.9),
                  AppTheme.primary.withOpacity(0.6),
                  AppTheme.primary.withOpacity(0.3),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Background pattern overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.5,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.healthSummary.value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                    letterSpacing: -0.015,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.summaryDescription.value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.analysisDateRange.value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAssessmentSection(AnalysisController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Assessment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textPrimaryLight,
            letterSpacing: -0.015,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Column(
            children: controller.riskAssessments.map((risk) {
              return _buildRiskItem(risk, controller, isDark);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskItem(
    dynamic risk,
    AnalysisController controller,
    bool isDark,
  ) {
    final riskColor = controller.getRiskLevelColor(risk.level);
    final riskText = controller.getRiskLevelText(risk.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconData(risk.icon),
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  risk.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  risk.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Risk Level Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              riskText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: riskColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySuggestionsSection(AnalysisController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Suggestions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textPrimaryLight,
            letterSpacing: -0.015,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Column(
            children: controller.activitySuggestions.map((suggestion) {
              return _buildSuggestionItem(suggestion, isDark);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionItem(dynamic suggestion, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconData(suggestion.icon),
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'This AI analysis is for informational purposes only and is not medical advice. Learn more.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'monitor_heart':
        return Icons.monitor_heart;
      case 'air':
        return Icons.air;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'self_improvement':
        return Icons.self_improvement;
      default:
        return Icons.info;
    }
  }
}
