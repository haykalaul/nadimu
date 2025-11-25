import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nadimu/controllers/dashboard_controller.dart';
import 'package:nadimu/routes/app_routes.dart';
import 'package:nadimu/themes/app_theme.dart';
import 'package:nadimu/views/widgets/line_chart_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Register controller if not already registered (for direct access from HomeScreen)
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController());
    }
    final controller = Get.find<DashboardController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nadimu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.account_circle,
                      size: 32,
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    ),
                    onPressed: () => Get.toNamed(AppRoutes.account),
                  ),
                ],
              ),
            ),
            // Connection Status
            Obx(() => Container(
                  color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        controller.isConnected.value ? 'ESP32 Connected' : 'Disconnected',
                        style: TextStyle(
                          color: controller.isConnected.value ? AppTheme.green : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // Heart Rate Card
                    Obx(() => _buildMetricCard(
                          context,
                          icon: Icons.favorite,
                          title: 'Heart Rate',
                          value: '${controller.heartRate.value} bpm',
                          status: 'Real-time',
                          change: '+2%',
                          changeColor: AppTheme.green,
                          chartData: controller.heartRateData,
                        )),
                    const SizedBox(height: 16),
                    // Oxygen Saturation Card
                    Obx(() => _buildMetricCard(
                          context,
                          icon: Icons.local_fire_department,
                          title: 'Oxygen Saturation',
                          value: '${controller.oxygenSaturation.value}%',
                          status: 'Real-time',
                          change: '-1%',
                          changeColor: AppTheme.orange,
                          chartData: controller.oxygenData,
                        )),
                    const SizedBox(height: 24),
                    // Activity Selector
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Current Activity',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ),
                        Obx(() => Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  _buildActivityButton(
                                    context,
                                    label: 'Walking',
                                    value: 'Walking',
                                    selected: controller.currentActivity.value == 'Walking',
                                    onTap: () => controller.changeActivity('Walking'),
                                  ),
                                  _buildActivityButton(
                                    context,
                                    label: 'Running',
                                    value: 'Running',
                                    selected: controller.currentActivity.value == 'Running',
                                    onTap: () => controller.changeActivity('Running'),
                                  ),
                                  _buildActivityButton(
                                    context,
                                    label: 'Rest',
                                    value: 'Rest',
                                    selected: controller.currentActivity.value == 'Rest',
                                    onTap: () => controller.changeActivity('Rest'),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Start Measurement Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: controller.startMeasurement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: AppTheme.primary.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Start Measurement',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.015,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String status,
    required String change,
    required Color changeColor,
    required List<double> chartData,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    change.startsWith('+') ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: changeColor,
                  ),
                  Text(
                    change,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: changeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChartWidget(data: chartData),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityButton(
    BuildContext context, {
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? AppTheme.cardDark : AppTheme.cardLight)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected
                    ? (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight)
                    : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}