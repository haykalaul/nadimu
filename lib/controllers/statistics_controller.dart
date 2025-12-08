import 'package:get/get.dart';
import 'package:nadimu/services/history_service.dart';

class StatisticsController extends GetxController {
  final HistoryService historyService = HistoryService();
  
  var filter = 'Daily'.obs;
  var avgHeartRate = 0.obs;
  var avgSpo2 = 0.obs;
  var highest = 0.obs;
  var lowest = 0.obs;
  var heartRateData = <double>[].obs;
  var spo2Data = <double>[].obs;
  var isLoading = true.obs;
  var hasData = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    try {
      isLoading.value = true;
      final days = filter.value == 'Daily' ? 1 : (filter.value == 'Weekly' ? 7 : 30);
      final measurements = await historyService.getRecentHistory(days);
      
      if (measurements.isEmpty) {
        hasData.value = false;
        heartRateData.value = [];
        spo2Data.value = [];
        avgHeartRate.value = 0;
        avgSpo2.value = 0;
        highest.value = 0;
        lowest.value = 0;
      } else {
        hasData.value = true;
        
        // Collect all heart rate and SpO2 values
        final allHeartRates = <double>[];
        final allSpo2s = <double>[];
        
        for (var measurement in measurements) {
          allHeartRates.add(measurement.heartRate.toDouble());
          allSpo2s.add(measurement.spo2.toDouble());
          
          // Add heart rate data points from each measurement
          heartRateData.addAll(measurement.heartRateData);
        }
        
        // Limit data points for chart (keep last 24 points)
        if (heartRateData.length > 24) {
          heartRateData.value = heartRateData.sublist(heartRateData.length - 24);
        }
        
        // Calculate statistics
        if (allHeartRates.isNotEmpty) {
          final sum = allHeartRates.fold(0.0, (a, b) => a + b);
          avgHeartRate.value = (sum / allHeartRates.length).round();
          highest.value = allHeartRates.reduce((a, b) => a > b ? a : b).round();
          lowest.value = allHeartRates.reduce((a, b) => a < b ? a : b).round();
        }
        
        if (allSpo2s.isNotEmpty) {
          final sum = allSpo2s.fold(0.0, (a, b) => a + b);
          avgSpo2.value = (sum / allSpo2s.length).round();
        }
        
        // Generate spo2 data for chart (use average for simplicity)
        if (avgSpo2.value > 0) {
          spo2Data.value = List.filled(heartRateData.length, avgSpo2.value.toDouble());
        }
      }
    } catch (e) {
      print('Error loading statistics: $e');
      hasData.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void changeFilter(String newFilter) {
    if (filter.value != newFilter) {
      filter.value = newFilter;
      loadStatistics();
    }
  }
}