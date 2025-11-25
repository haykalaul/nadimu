import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nadimu/controllers/monitoring_controller.dart';
import 'package:nadimu/themes/app_theme.dart';
import 'package:nadimu/views/widgets/line_chart_widget.dart';

class RealtimeMonitoringScreen extends StatelessWidget {
  const RealtimeMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MonitoringController>()) {
      Get.put(MonitoringController());
    }
    final controller = Get.find<MonitoringController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF333333)),
                    onPressed: () => Get.back(),
                  ),
                  const Spacer(),
                  Text(
                    'Live Monitoring',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF333333),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'History',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // Status Indicator Card
                    Obx(() {
                      final status = controller.status.value;
                      final color = _statusColor(status);
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Health Status',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _getStatusIcon(status),
                              color: color,
                              size: 24,
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    // Heart Rate Card
                    Obx(() => _MetricCard(
                          icon: Icons.monitor_heart,
                          title: 'Heart Rate (BPM)',
                          value: controller.heartRate.value.toString(),
                          child: SizedBox(
                            height: 140,
                            child: LineChartWidget(data: controller.heartRateData),
                          ),
                        )),
                    const SizedBox(height: 16),
                    // SpO2 Card
                    Obx(() => _MetricCard(
                          icon: Icons.bloodtype,
                          title: 'Oxygen Saturation (SpO₂)',
                          value: controller.spo2.value.toString(),
                          unit: '%',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: controller.spo2.value / 100,
                                  minHeight: 10,
                                  backgroundColor: Colors.grey[200]?.withOpacity(0.6),
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                    // Activity Mode
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        'Activity Mode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                    Obx(() => Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              _buildActivityChip(
                                label: 'Resting',
                                selected: controller.activityMode.value == 'Resting',
                                onTap: () => controller.changeActivity('Resting'),
                                isDark: isDark,
                              ),
                              _buildActivityChip(
                                label: 'Walking',
                                selected: controller.activityMode.value == 'Walking',
                                onTap: () => controller.changeActivity('Walking'),
                                isDark: isDark,
                              ),
                              _buildActivityChip(
                                label: 'Exercise',
                                selected: controller.activityMode.value == 'Exercise',
                                onTap: () => controller.changeActivity('Exercise'),
                                isDark: isDark,
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: controller.stopMonitoring,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          elevation: 6,
                          shadowColor: AppTheme.primary.withOpacity(0.3),
                        ),
                        child: const Text(
                          'Stop Monitoring',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return const Color(0xFF28A745);
      case 'alert':
        return const Color(0xFFFFC107);
      case 'danger':
        return AppTheme.primary;
      default:
        return const Color(0xFF28A745);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return Icons.check_circle;
      case 'alert':
        return Icons.warning;
      case 'danger':
        return Icons.error;
      default:
        return Icons.check_circle;
    }
  }

  Widget _buildActivityChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? (isDark ? Colors.grey[700] : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: selected
                    ? (isDark ? Colors.white : const Color(0xFF333333))
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? unit;
  final Widget child;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.child,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 32, color: AppTheme.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF333333),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 8),
                Text(
                  unit!,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}