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
                  Obx(() => IconButton(
                    icon: Icon(
                      controller.isConnected.value ? Icons.wifi : Icons.wifi_off,
                      color: controller.isConnected.value ? Colors.green : Colors.red,
                    ),
                    onPressed: () {
                      if (!controller.isConnected.value) {
                        controller.connectMqtt();
                      }
                    },
                    tooltip: controller.isConnected.value ? 'Connected' : 'Disconnected',
                  )),
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
                    // Connection Status Card
                    Obx(() => _ConnectionStatusCard(
                      isConnected: controller.isConnected.value,
                      statusMessage: controller.statusMessage.value,
                      statusColor: controller.getStatusColor(),
                      statusDisplay: controller.getStatusDisplay(),
                      lastUpdate: controller.lastUpdateTime.value,
                      isDark: isDark,
                    )),
                    const SizedBox(height: 20),
                    // Heart Rate Card
                    Obx(() => _MetricCard(
                      icon: Icons.monitor_heart,
                      title: 'Heart Rate',
                      value: controller.heartRate.value > 0 
                          ? controller.heartRate.value.toString() 
                          : '--',
                      unit: 'BPM',
                      child: controller.heartRate.value > 0
                          ? SizedBox(
                              height: 140,
                              child: LineChartWidget(data: controller.heartRateData),
                            )
                          : _buildEmptyState('No data received yet', isDark),
                      isDark: isDark,
                    )),
                    const SizedBox(height: 16),
                    // SpO2 Card
                    Obx(() => _MetricCard(
                      icon: Icons.bloodtype,
                      title: 'Oxygen Saturation',
                      value: controller.spo2.value > 0 
                          ? controller.spo2.value.toString() 
                          : '--',
                      unit: '%',
                      child: controller.spo2.value > 0
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: controller.spo2.value / 100,
                                    minHeight: 12,
                                    backgroundColor: Colors.grey[200]?.withOpacity(0.6),
                                    color: _getSpO2Color(controller.spo2.value),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getSpO2Status(controller.spo2.value),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getSpO2Color(controller.spo2.value),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : _buildEmptyState('No data received yet', isDark),
                      isDark: isDark,
                    )),
                    const SizedBox(height: 16),
                    // Quality Indicator Card
                    Obx(() => _QualityCard(
                      quality: controller.quality.value,
                      isDark: isDark,
                    )),
                    const SizedBox(height: 24),
                    // Command Buttons
                    Text(
                      'Device Control',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(() => Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: controller.isConnected.value
                                ? () { controller.resetAndSend(); }
                                : () { controller.resetDisplay(); },
                            icon: const Icon(Icons.refresh, size: 20),
                            label: const Text('Reset Device'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: controller.isConnected.value
                                ? null
                                : () { controller.connectMqtt(); },
                            icon: const Icon(Icons.refresh, size: 20),
                            label: const Text('Reconnect'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: AppTheme.primary),
                            ),
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(height: 16),
                    // Info Card
                    _InfoCard(isDark: isDark),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: controller.stopMonitoring,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                          shadowColor: Colors.red.withOpacity(0.3),
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

  Widget _buildEmptyState(String message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Color _getSpO2Color(int spo2) {
    if (spo2 >= 95) return const Color(0xFF28A745);
    if (spo2 >= 90) return const Color(0xFFFFC107);
    return Colors.red;
  }

  String _getSpO2Status(int spo2) {
    if (spo2 >= 95) return 'Normal';
    if (spo2 >= 90) return 'Low';
    return 'Critical';
  }
}

class _ConnectionStatusCard extends StatelessWidget {
  final bool isConnected;
  final String statusMessage;
  final Color statusColor;
  final String statusDisplay;
  final DateTime lastUpdate;
  final bool isDark;

  const _ConnectionStatusCard({
    required this.isConnected,
    required this.statusMessage,
    required this.statusColor,
    required this.statusDisplay,
    required this.lastUpdate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.5),
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
                      'Device Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusDisplay,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isConnected ? Icons.check_circle : Icons.error_outline,
                color: statusColor,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.grey[800] : Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            statusMessage,
            style: TextStyle(
              fontSize: 13,
              color: isConnected ? const Color(0xFF28A745) : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
          if (lastUpdate.difference(DateTime.now()).inSeconds.abs() < 60)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Last update: ${_formatTime(lastUpdate)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}

class _QualityCard extends StatelessWidget {
  final int quality;
  final bool isDark;

  const _QualityCard({
    required this.quality,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.signal_cellular_alt, color: AppTheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signal Quality',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index < quality
                            ? AppTheme.primary
                            : (isDark ? Colors.grey[700] : Colors.grey[300]),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          Text(
            '$quality/3',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final bool isDark;

  const _InfoCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Place your finger on the sensor and wait for measurement to complete.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.blue[200] : Colors.blue[800],
              ),
            ),
          ),
        ],
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
  final bool isDark;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.child,
    this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    unit!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
