import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nadimu/controllers/connection_controller.dart';
import 'package:nadimu/themes/app_theme.dart';
import 'package:nadimu/services/mqtt_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class IotConnectionScreen extends StatelessWidget {
  const IotConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Register controller if not already registered
    if (!Get.isRegistered<ConnectionController>()) {
      Get.put(ConnectionController());
    }
    final controller = Get.find<ConnectionController>();
    final mqttService = MqttService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Sync connection status with MQTT service
    controller.isConnected.value = mqttService.isConnected;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.grey[200] : Colors.grey[800],
                      ),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  Text(
                    'MQTT Connection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            // Status Indicator Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Obx(() => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark.withOpacity(0.5) : AppTheme.cardLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.isConnected.value
                            ? AppTheme.green.withOpacity(0.5)
                            : Colors.red.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: controller.isConnected.value
                                ? AppTheme.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            controller.isConnected.value ? Icons.wifi : Icons.wifi_off,
                            color: controller.isConnected.value ? AppTheme.green : Colors.red,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MQTT Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                controller.isConnected.value ? 'Connected' : 'Disconnected',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: controller.isConnected.value
                                      ? AppTheme.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (controller.isConnected.value)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.green,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )),
            ),
            // Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Connect to MQTT Broker',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect to broker.mqtt.cool to receive real-time sensor data from your ESP32 device.',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // MQTT Info Card
                    _MqttInfoCard(isDark: isDark),
                    const SizedBox(height: 24),
                    // Topics Info
                    Text(
                      'Subscribed Topics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TopicCard(
                      topic: 'pulseox/data',
                      description: 'Complete measurement data (JSON)',
                      icon: Icons.data_object,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _TopicCard(
                      topic: 'pulseox/status',
                      description: 'Device status messages',
                      icon: Icons.info_outline,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _TopicCard(
                      topic: 'pulseox/heartrate',
                      description: 'Heart rate value only',
                      icon: Icons.monitor_heart,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _TopicCard(
                      topic: 'pulseox/spo2',
                      description: 'SpO2 value only',
                      icon: Icons.bloodtype,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _TopicCard(
                      topic: 'pulseox/command',
                      description: 'Send commands to device',
                      icon: Icons.send,
                      isDark: isDark,
                      isCommand: true,
                    ),
                    const SizedBox(height: 100), // Space for footer
                  ],
                ),
              ),
            ),
            // Action Buttons Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight).withOpacity(0.8),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: controller.isConnected.value
                              ? null
                              : () async {
                                  controller.isConnecting.value = true;
                                  final mqttService = MqttService();
                                  final success = await mqttService.connect();
                                  controller.isConnecting.value = false;
                                  
                                  if (success) {
                                    controller.isConnected.value = true;
                                    Fluttertoast.showToast(
                                      msg: 'Connected to MQTT broker',
                                      toastLength: Toast.LENGTH_SHORT,
                                      backgroundColor: AppTheme.green,
                                    );
                                    // Navigate to monitoring screen
                                    Get.toNamed('/realtime-monitoring');
                                  } else {
                                    Fluttertoast.showToast(
                                      msg: 'Failed to connect to MQTT broker',
                                      toastLength: Toast.LENGTH_SHORT,
                                      backgroundColor: Colors.red,
                                    );
                                  }
                                },
                          icon: controller.isConnecting.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(
                                  controller.isConnected.value ? Icons.check_circle : Icons.wifi,
                                  size: 20,
                                ),
                          label: Text(
                            controller.isConnecting.value
                                ? 'Connecting...'
                                : controller.isConnected.value
                                    ? 'Connected'
                                    : 'Connect to MQTT',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: controller.isConnected.value
                                ? AppTheme.green
                                : AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: AppTheme.green,
                          ),
                        ),
                      )),
                  const SizedBox(height: 12),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: controller.isConnected.value
                              ? () {
                                  mqttService.disconnect();
                                  controller.isConnected.value = false;
                                  Fluttertoast.showToast(
                                    msg: 'Disconnected from MQTT broker',
                                    toastLength: Toast.LENGTH_SHORT,
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.close, size: 20),
                          label: const Text('Disconnect'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MqttInfoCard extends StatelessWidget {
  final bool isDark;

  const _MqttInfoCard({required this.isDark});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Text(
                'MQTT Broker Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.blue[200] : Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Broker',
            value: 'broker.mqtt.cool',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Port',
            value: '1883',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Protocol',
            value: 'MQTT',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.blue[200] : Colors.blue[800],
          ),
        ),
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  final String topic;
  final String description;
  final IconData icon;
  final bool isDark;
  final bool isCommand;

  const _TopicCard({
    required this.topic,
    required this.description,
    required this.icon,
    required this.isDark,
    this.isCommand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark.withOpacity(0.5) : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCommand
              ? AppTheme.primary.withOpacity(0.3)
              : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCommand
                  ? AppTheme.primary.withOpacity(0.1)
                  : AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isCommand ? AppTheme.primary : AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isCommand)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'PUBLISH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'SUBSCRIBE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
