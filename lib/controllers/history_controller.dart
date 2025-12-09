import 'package:get/get.dart';
import 'package:nadimu/services/history_service.dart';
import 'package:nadimu/models/measurement_history.dart';

class HistoryController extends GetxController {
  final HistoryService historyService = HistoryService();
  
  var historyList = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var selectedDateRange = 7.obs; // Default 7 days
  
  // Statistics
  var averageHeartRate = 0.0.obs;
  var averageSpO2 = 0.0.obs;
  var totalMeasurements = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
    loadStatistics();
  }

  // Load recent history from Supabase
  Future<void> loadHistory() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final measurements = await historyService.getRecentHistory(selectedDateRange.value);
      
      historyList.value = measurements.map((m) => {
        'id': m.id,
        'date': m.formattedDate,
        'label': m.dateLabel,
        'status': m.statusLabel,
        'avgHeartRate': m.heartRate,
        'avgSpo2': m.spO2,
        'timestamp': m.timestamp.toIso8601String(),
        'time': m.formattedTime,
        'quality': m.quality,
        'activityMode': m.activityMode,
        'duration': m.duration,
        'heartRateData': m.heartRateData,
        'statusMessage': m.status,
        'notes': m.notes,
      }).toList();
      
      print('✅ Loaded ${historyList.length} measurements from Supabase');
    } catch (e) {
      print('❌ Error loading history: $e');
      errorMessage.value = 'Failed to load history: $e';
      historyList.value = [];
      
      // Show error snackbar
      Get.snackbar(
        'Error',
        'Failed to load measurement history',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load all history from Supabase
  Future<void> loadAllHistory() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final measurements = await historyService.getAllHistory();
      
      historyList.value = measurements.map((m) => {
        'id': m.id,
        'date': m.formattedDate,
        'label': m.dateLabel,
        'status': m.statusLabel,
        'avgHeartRate': m.heartRate,
        'avgSpo2': m.spO2,
        'timestamp': m.timestamp.toIso8601String(),
        'time': m.formattedTime,
        'quality': m.quality,
        'activityMode': m.activityMode,
        'duration': m.duration,
        'heartRateData': m.heartRateData,
        'statusMessage': m.status,
        'notes': m.notes,
      }).toList();
      
      print('✅ Loaded ${historyList.length} total measurements from Supabase');
    } catch (e) {
      print('❌ Error loading full history: $e');
      errorMessage.value = 'Failed to load full history: $e';
      
      Get.snackbar(
        'Error',
        'Failed to load full history',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load history by date range
  Future<void> loadHistoryByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final measurements = await historyService.getHistoryByDateRange(startDate, endDate);
      
      historyList.value = measurements.map((m) => {
        'id': m.id,
        'date': m.formattedDate,
        'label': m.dateLabel,
        'status': m.statusLabel,
        'avgHeartRate': m.heartRate,
        'avgSpo2': m.spO2,
        'timestamp': m.timestamp.toIso8601String(),
        'time': m.formattedTime,
        'quality': m.quality,
        'activityMode': m.activityMode,
        'duration': m.duration,
        'heartRateData': m.heartRateData,
        'statusMessage': m.status,
        'notes': m.notes,
      }).toList();
      
      print('✅ Loaded ${historyList.length} measurements for date range');
    } catch (e) {
      print('❌ Error loading history by date range: $e');
      errorMessage.value = 'Failed to load history: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Load statistics from Supabase
  Future<void> loadStatistics() async {
    try {
      final stats = await historyService.getStatisticsSummary(selectedDateRange.value);
      
      if (stats.isNotEmpty) {
        averageHeartRate.value = stats['averageHeartRate']?.toDouble() ?? 0.0;
        averageSpO2.value = stats['averageSpO2']?.toDouble() ?? 0.0;
        totalMeasurements.value = stats['totalMeasurements'] ?? 0;
        
        print('✅ Statistics loaded: HR=${averageHeartRate.value}, SpO2=${averageSpO2.value}');
      }
    } catch (e) {
      print('❌ Error loading statistics: $e');
    }
  }

  // Delete measurement from Supabase
  Future<void> deleteMeasurement(String id) async {
    try {
      isLoading.value = true;
      
      final success = await historyService.deleteMeasurement(id);
      
      if (success) {
        // Remove from local list
        historyList.removeWhere((item) => item['id'] == id);
        
        Get.snackbar(
          'Success',
          'Measurement deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        
        // Refresh statistics
        await loadStatistics();
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete measurement',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('❌ Error deleting measurement: $e');
      Get.snackbar(
        'Error',
        'Failed to delete measurement: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Clear all history from Supabase
  Future<void> clearAllHistory() async {
    try {
      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Clear All History'),
          content: const Text('Are you sure you want to delete all measurement history? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete All'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        isLoading.value = true;
        
        final success = await historyService.clearAllHistory();
        
        if (success) {
          historyList.clear();
          averageHeartRate.value = 0.0;
          averageSpO2.value = 0.0;
          totalMeasurements.value = 0;
          
          Get.snackbar(
            'Success',
            'All history cleared successfully',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        } else {
          Get.snackbar(
            'Error',
            'Failed to clear history',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      print('❌ Error clearing history: $e');
      Get.snackbar(
        'Error',
        'Failed to clear history: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Sync local data to Supabase
  Future<void> syncLocalToCloud() async {
    try {
      isLoading.value = true;
      
      Get.snackbar(
        'Syncing',
        'Syncing local data to cloud...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      
      final success = await historyService.syncLocalToSupabase();
      
      if (success) {
        Get.snackbar(
          'Success',
          'Data synced successfully',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        
        // Reload history after sync
        await loadHistory();
      } else {
        Get.snackbar(
          'Error',
          'Failed to sync data',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('❌ Error syncing data: $e');
      Get.snackbar(
        'Error',
        'Failed to sync data: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Change date range filter
  void changeDateRange(int days) {
    selectedDateRange.value = days;
    loadHistory();
    loadStatistics();
  }

  // View measurement details
  void viewDetails(int index) {
    if (index >= 0 && index < historyList.length) {
      Get.toNamed('/history-details', arguments: historyList[index]);
    }
  }

  // View full history
  void viewFullHistory() {
    loadAllHistory();
  }

  // Refresh history
  Future<void> refreshHistory() async {
    await loadHistory();
    await loadStatistics();
  }

  // Export data (for future feature)
  Future<void> exportData() async {
    try {
      final measurements = await historyService.getAllHistory();
      
      // TODO: Implement export to CSV or JSON
      Get.snackbar(
        'Info',
        'Export feature coming soon! ${measurements.length} measurements ready.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('❌ Error exporting data: $e');
    }
  }
}