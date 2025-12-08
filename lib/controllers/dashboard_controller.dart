import 'package:get/get.dart';
import 'package:nadimu/routes/app_routes.dart';
import 'package:nadimu/services/history_service.dart';
import 'package:nadimu/services/mqtt_service.dart';

class DashboardController extends GetxController {
  final HistoryService historyService = HistoryService();
  final MqttService mqttService = MqttService();
  void Function(bool)? _connListener;

  var heartRate = 0.obs;
  var oxygenSaturation = 0.obs;
  var isConnected = false.obs;
  var currentActivity = 'Resting'.obs;
  var heartRateData = <double>[].obs;
  var oxygenData = <double>[].obs;
  var hasData = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadLatestMeasurement();
    refreshConnection();
    _connListener = (connected) {
      isConnected.value = connected;
    };
    mqttService.addConnectionListener(_connListener!);
  }

  Future<void> loadLatestMeasurement() async {
    try {
      final measurements = await historyService.getRecentHistory(
        1,
      ); // Today's measurements
      if (measurements.isNotEmpty) {
        final latest = measurements.first;
        heartRate.value = latest.heartRate;
        oxygenSaturation.value = latest.spo2;
        heartRateData.value = List<double>.from(latest.heartRateData);
        currentActivity.value = latest.activityMode;
        hasData.value = true;
      } else {
        hasData.value = false;
      }
      isConnected.value = mqttService.isConnected;
    } catch (e) {
      print('Error loading latest measurement: $e');
      hasData.value = false;
    }
  }

  void startMeasurement() {
    if (mqttService.isConnected) {
      Get.toNamed(AppRoutes.realtimeMonitoring);
    } else {
      Get.toNamed(AppRoutes.iotConnection);
    }
  }

  void changeActivity(String activity) {
    currentActivity.value = activity;
  }

  Future<void> refresh() async {
    await loadLatestMeasurement();
  }

  void refreshConnection() {
    isConnected.value = mqttService.isConnected;
  }

  @override
  void onClose() {
    if (_connListener != null) {
      mqttService.removeConnectionListener(_connListener!);
    }
    super.onClose();
  }
}
