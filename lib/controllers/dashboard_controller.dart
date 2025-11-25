import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:nadimu/routes/app_routes.dart';

class DashboardController extends GetxController {
  var heartRate = 85.obs;
  var oxygenSaturation = 98.obs;
  var isConnected = true.obs;
  var currentActivity = 'Walking'.obs;
  var heartRateData = <double>[].obs; // Untuk chart
  var oxygenData = <double>[].obs;

  @override
  void onInit() {
    super.onInit();
    simulateData();
  }

  void simulateData() {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      heartRate.value = 70 + Random().nextInt(30);
      oxygenSaturation.value = 95 + Random().nextInt(5);
      heartRateData.add(heartRate.value.toDouble());
      oxygenData.add(oxygenSaturation.value.toDouble());
      if (heartRateData.length > 20) heartRateData.removeAt(0);
      if (oxygenData.length > 20) oxygenData.removeAt(0);
    });
  }

  void startMeasurement() {
    Get.toNamed(AppRoutes.iotConnection);
  }

  void changeActivity(String activity) {
    currentActivity.value = activity;
  }
}