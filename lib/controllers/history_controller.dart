import 'package:get/get.dart';
import 'package:nadimu/services/history_service.dart';

class HistoryController extends GetxController {
  final HistoryService historyService = HistoryService();
  var historyList = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      isLoading.value = true;
      final measurements = await historyService.getRecentHistory(7); // Last 7 days
      
      historyList.value = measurements.map((m) => {
        'id': m.id,
        'date': m.formattedDate,
        'label': m.dateLabel,
        'status': m.statusLabel,
        'avgHeartRate': m.heartRate,
        'avgSpo2': m.spo2,
        'timestamp': m.timestamp.toIso8601String(),
        'time': m.formattedTime,
        'quality': m.quality,
        'activityMode': m.activityMode,
        'duration': m.duration,
        'heartRateData': m.heartRateData,
        'statusMessage': m.status,
      }).toList();
    } catch (e) {
      print('Error loading history: $e');
      historyList.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  void viewDetails(int index) {
    if (index >= 0 && index < historyList.length) {
      Get.toNamed('/history-details', arguments: historyList[index]);
    }
  }

  void viewFullHistory() {
    // Load all history (not just 7 days)
    loadAllHistory();
  }

  Future<void> loadAllHistory() async {
    try {
      isLoading.value = true;
      final measurements = await historyService.getAllHistory();
      
      historyList.value = measurements.map((m) => {
        'id': m.id,
        'date': m.formattedDate,
        'label': m.dateLabel,
        'status': m.statusLabel,
        'avgHeartRate': m.heartRate,
        'avgSpo2': m.spo2,
        'timestamp': m.timestamp.toIso8601String(),
        'time': m.formattedTime,
        'quality': m.quality,
        'activityMode': m.activityMode,
        'duration': m.duration,
        'heartRateData': m.heartRateData,
        'statusMessage': m.status,
      }).toList();
    } catch (e) {
      print('Error loading full history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshHistory() async {
    await loadHistory();
  }
}