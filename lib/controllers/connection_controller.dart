import 'package:get/get.dart';
import 'package:nadimu/routes/app_routes.dart';

class ConnectionController extends GetxController {
  var connectionType = 'MQTT'.obs;
  var isConnected = false.obs;
  var isConnecting = false.obs;
  var devices = ['ESP32-Health-Monitor', 'HeartRate-Sensor-7B'].obs;

  void changeConnectionType(String type) {
    connectionType.value = type;
  }

  String? lastConnectedDevice;

  void connectDevice(String device) {
    isConnected.value = true;
    lastConnectedDevice = device;
    Get.toNamed(AppRoutes.realtimeMonitoring);
  }

  void scanDevices() {
    // Simulasi scan
    devices.add('New Device ${devices.length + 1}');
  }

  void testConnection() {
    // Connection test logic here
    // Snackbar will be shown from UI
  }
}