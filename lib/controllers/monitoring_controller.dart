import 'dart:async';
import 'package:get/get.dart';
import 'package:nadimu/models/pulseox_data.dart';
import 'package:nadimu/models/measurement_history.dart';
import 'package:nadimu/services/mqtt_service.dart';
import 'package:nadimu/services/history_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class MonitoringController extends GetxController {
  final MqttService mqttService = MqttService();
  final HistoryService historyService = HistoryService();
  
  var heartRate = 0.obs;
  var spo2 = 0.obs;
  var quality = 0.obs;
  var statusMessage = 'Connecting...'.obs;
  var isConnected = false.obs;
  var activityMode = 'Resting'.obs;
  var heartRateData = <double>[].obs;
  var lastUpdateTime = DateTime.now().obs;
  DateTime? _startTime;

  @override
  void onInit() {
    super.onInit();
    _startTime = DateTime.now();
    _setupMqttCallbacks();
    // Check if already connected, if not then connect
    if (!mqttService.isConnected) {
      connectMqtt();
    } else {
      isConnected.value = true;
      statusMessage.value = 'Connected';
      // Ensure message handlers are set up
      mqttService.ensureMessageHandlers();
    }
  }

  void _setupMqttCallbacks() {
    mqttService.onDataReceived = (PulseOxData data) {
      heartRate.value = data.heartrate;
      spo2.value = data.spo2;
      quality.value = data.quality;
      lastUpdateTime.value = DateTime.now();
      
      // Add to chart data
      heartRateData.add(data.heartrate.toDouble());
      if (heartRateData.length > 30) {
        heartRateData.removeAt(0);
      }
    };

    mqttService.onStatusReceived = (String status) {
      statusMessage.value = status;
    };

    mqttService.onHeartRateReceived = (String value) {
      try {
        final hr = int.tryParse(value);
        if (hr != null) {
          heartRate.value = hr;
          heartRateData.add(hr.toDouble());
          if (heartRateData.length > 30) {
            heartRateData.removeAt(0);
          }
        }
      } catch (e) {
        print('Error parsing heartrate: $e');
      }
    };

    mqttService.onSpO2Received = (String value) {
      try {
        final sp = int.tryParse(value);
        if (sp != null) {
          spo2.value = sp;
        }
      } catch (e) {
        print('Error parsing spo2: $e');
      }
    };

    mqttService.onConnectionChanged = (bool connected) {
      isConnected.value = connected;
      if (connected) {
        statusMessage.value = 'Connected';
      } else {
        statusMessage.value = 'Disconnected';
      }
    };
  }

  Future<void> connectMqtt() async {
    statusMessage.value = 'Connecting to MQTT...';
    final success = await mqttService.connect();
    if (success) {
      statusMessage.value = 'Connected';
      Fluttertoast.showToast(
        msg: 'Connected to MQTT broker',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Get.theme.colorScheme.primary,
      );
    } else {
      statusMessage.value = 'Connection failed';
      Fluttertoast.showToast(
        msg: 'Failed to connect to MQTT broker',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> sendCommand(String command) async {
    final success = await mqttService.publishCommand(command);
    if (success) {
      Fluttertoast.showToast(
        msg: 'Command sent: $command',
        toastLength: Toast.LENGTH_SHORT,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to send command',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
      );
    }
  }

  void resetDisplay() {
    heartRate.value = 0;
    spo2.value = 0;
    quality.value = 0;
    heartRateData.clear();
    statusMessage.value = 'Reset';
    lastUpdateTime.value = DateTime.now();
  }

  Future<void> resetAndSend() async {
    resetDisplay();
    await sendCommand('RESET');
  }

  Future<void> stopMonitoring() async {
    // Save measurement to history if we have valid data
    if (heartRate.value > 0 && spo2.value > 0 && _startTime != null) {
      final duration = DateTime.now().difference(_startTime!).inSeconds;
      
      // Only save if measurement was meaningful (at least 10 seconds)
      if (duration >= 10) {
        final measurement = MeasurementHistory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          timestamp: _startTime!,
          heartRate: heartRate.value,
          spo2: spo2.value,
          quality: quality.value,
          status: statusMessage.value,
          activityMode: activityMode.value,
          heartRateData: List<double>.from(heartRateData),
          duration: duration,
        );

        final saved = await historyService.saveMeasurement(measurement);
        if (saved) {
          Fluttertoast.showToast(
            msg: 'Measurement saved to history',
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.green,
          );
        } else {
          Fluttertoast.showToast(
            msg: 'Failed to save measurement',
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.orange,
          );
        }
      }
    }
    
    mqttService.disconnect();
    Get.back();
  }

  void changeActivity(String mode) {
    activityMode.value = mode;
  }

  String getStatusDisplay() {
    final status = statusMessage.value;
    if (status.contains('READY') || status.contains('ONLINE')) {
      return 'Ready';
    } else if (status.contains('MEASURING') || status.contains('Starting')) {
      return 'Measuring...';
    } else if (status.contains('COMPLETE')) {
      return 'Complete';
    } else if (status.contains('ERROR')) {
      return 'Error';
    } else if (status.contains('RESET')) {
      return 'Reset';
    } else if (status.contains('Finger')) {
      return 'Waiting for finger...';
    }
    return status;
  }

  Color getStatusColor() {
    final status = statusMessage.value.toLowerCase();
    if (status.contains('ready') || status.contains('online') || status.contains('complete') || status.contains('connected')) {
      return const Color(0xFF28A745);
    } else if (status.contains('measuring') || status.contains('starting') || status.contains('stabilizing')) {
      return const Color(0xFFFFC107);
    } else if (status.contains('error')) {
      return Colors.red;
    } else if (status.contains('reset')) {
      return const Color(0xFF17A2B8);
    }
    return Colors.grey;
  }

  @override
  void onClose() {
    mqttService.disconnect();
    super.onClose();
  }
}
