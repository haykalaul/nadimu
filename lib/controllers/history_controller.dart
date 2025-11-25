import 'package:get/get.dart';

class HistoryController extends GetxController {
  var historyList = [
    {
      'date': 'October 26, 2023',
      'label': 'Today',
      'status': 'Normal',
      'avgHeartRate': 78,
      'avgSpo2': 98,
    },
    {
      'date': 'October 25, 2023',
      'label': 'Yesterday',
      'status': 'Normal',
      'avgHeartRate': 85,
      'avgSpo2': 96,
    },
    {
      'date': 'October 24, 2023',
      'label': 'Tuesday',
      'status': 'Alert',
      'avgHeartRate': 92,
      'avgSpo2': 94,
    },
    {
      'date': 'October 23, 2023',
      'label': 'Monday',
      'status': 'Normal',
      'avgHeartRate': 76,
      'avgSpo2': 97,
    },
    {
      'date': 'October 22, 2023',
      'label': 'Sunday',
      'status': 'Danger',
      'avgHeartRate': 110,
      'avgSpo2': 90,
    },
    {
      'date': 'October 21, 2023',
      'label': 'Saturday',
      'status': 'Normal',
      'avgHeartRate': 82,
      'avgSpo2': 99,
    },
    {
      'date': 'October 20, 2023',
      'label': 'Friday',
      'status': 'Normal',
      'avgHeartRate': 74,
      'avgSpo2': 97,
    },
  ].obs;

  void viewDetails(int index) {
    Get.toNamed('/history-details', arguments: historyList[index]);
  }

  void viewFullHistory() {
    Get.snackbar('Full History', 'Viewing full history');
  }
}