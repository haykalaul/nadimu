import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

class MonitoringController extends GetxController {
  var heartRate = 75.obs;
  var spo2 = 98.obs;
  var status = 'NORMAL'.obs;
  var activityMode = 'Resting'.obs;
  var heartRateData = <double>[].obs;

  Timer? timer;

  @override
  void onInit() {
    super.onInit();
    startMonitoring();
  }

  void startMonitoring() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      heartRate.value = 70 + Random().nextInt(10);
      spo2.value = 95 + Random().nextInt(5);
      heartRateData.add(heartRate.value.toDouble());
      if (heartRateData.length > 15) heartRateData.removeAt(0);
      status.value = spo2.value > 95 ? 'NORMAL' : 'ALERT';
    });
  }

  void stopMonitoring() {
    timer?.cancel();
    Get.back();
  }

  void changeActivity(String mode) {
    activityMode.value = mode;
  }
}