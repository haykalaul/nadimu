import 'dart:math';

import 'package:get/get.dart';

class StatisticsController extends GetxController {
  var filter = 'Daily'.obs;
  var avgHeartRate = 72.obs;
  var avgSpo2 = 98.obs;
  var highest = 110.obs;
  var lowest = 65.obs;
  var heartRateData = <double>[].obs;
  var spo2Data = <double>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with default data immediately to prevent empty list issues
    _initializeDefaultData();
    // Generate data synchronously since we already have default data
    // This ensures data is ready when widget builds
    generateData();
  }

  void _initializeDefaultData() {
    // Initialize with default values to prevent crashes
    if (heartRateData.isEmpty) {
      heartRateData.value = List.filled(24, 70.0);
    }
    if (spo2Data.isEmpty) {
      spo2Data.value = List.filled(24, 95.0);
    }
  }

  void generateData() {
    try {
      final random = Random();
      final newHeartRateData = List<double>.generate(24, (_) => 60 + random.nextInt(50).toDouble());
      final newSpo2Data = List<double>.generate(24, (_) => 90 + random.nextInt(10).toDouble());

      // Use value assignment to trigger reactive updates safely
      heartRateData.value = newHeartRateData;
      spo2Data.value = newSpo2Data;
      
      // Update statistics based on generated data
      _updateStatistics();
    } catch (e) {
      // Fallback to default data if generation fails
      _initializeDefaultData();
    }
  }

  void _updateStatistics() {
    if (heartRateData.isNotEmpty) {
      final sum = heartRateData.fold(0.0, (a, b) => a + b);
      avgHeartRate.value = (sum / heartRateData.length).round();
      highest.value = heartRateData.reduce((a, b) => a > b ? a : b).round();
      lowest.value = heartRateData.reduce((a, b) => a < b ? a : b).round();
    }
    if (spo2Data.isNotEmpty) {
      final sum = spo2Data.fold(0.0, (a, b) => a + b);
      avgSpo2.value = (sum / spo2Data.length).round();
    }
  }

  void changeFilter(String newFilter) {
    if (filter.value != newFilter) {
      filter.value = newFilter;
      // Regenerate data based on filter
      generateData();
    }
  }
}