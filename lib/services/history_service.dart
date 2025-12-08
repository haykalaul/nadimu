import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nadimu/models/measurement_history.dart';

class HistoryService {
  static const String _historyKey = 'measurement_history';
  static const int _maxHistoryItems = 100; // Limit to prevent storage bloat

  Future<List<MeasurementHistory>> getAllHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      return historyJson
          .map((jsonStr) => MeasurementHistory.fromJson(json.decode(jsonStr) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }

  Future<bool> saveMeasurement(MeasurementHistory measurement) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      // Add new measurement
      historyJson.insert(0, json.encode(measurement.toJson()));
      
      // Limit history size
      if (historyJson.length > _maxHistoryItems) {
        historyJson.removeRange(_maxHistoryItems, historyJson.length);
      }
      
      return await prefs.setStringList(_historyKey, historyJson);
    } catch (e) {
      print('Error saving measurement: $e');
      return false;
    }
  }

  Future<bool> deleteMeasurement(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      historyJson.removeWhere((jsonStr) {
        final data = json.decode(jsonStr) as Map<String, dynamic>;
        return data['id'] == id;
      });
      
      return await prefs.setStringList(_historyKey, historyJson);
    } catch (e) {
      print('Error deleting measurement: $e');
      return false;
    }
  }

  Future<bool> clearAllHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_historyKey);
    } catch (e) {
      print('Error clearing history: $e');
      return false;
    }
  }

  Future<List<MeasurementHistory>> getRecentHistory(int days) async {
    final allHistory = await getAllHistory();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return allHistory.where((m) => m.timestamp.isAfter(cutoffDate)).toList();
  }
}

