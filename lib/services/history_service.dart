import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nadimu/models/measurement_history.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryService {
  static const String _historyKey = 'measurement_history';
  static const int _maxHistoryItems = 100; // Limit to prevent storage bloat
  
  // Supabase client
  final SupabaseClient supabase = Supabase.instance.client;

  // Get all history from Supabase
  Future<List<MeasurementHistory>> getAllHistory() async {
    try {
      final data = await supabase
          .from('measurement_history')
          .select()
          .order('timestamp', ascending: false);
      
      return (data as List)
          .map((item) => MeasurementHistory.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading history from Supabase: $e');
      // Fallback to local storage if Supabase fails
      return await _getLocalHistory();
    }
  }

  // Fallback: Get local history from SharedPreferences
  Future<List<MeasurementHistory>> _getLocalHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      return historyJson
          .map((jsonStr) => MeasurementHistory.fromJson(json.decode(jsonStr) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error loading local history: $e');
      return [];
    }
  }

  // Save measurement to Supabase
  Future<bool> saveMeasurement(MeasurementHistory measurement) async {
    try {
      // Save to Supabase
      await supabase.from('measurement_history').insert(measurement.toJson());
      
      // Also save to local storage as backup
      await _saveToLocal(measurement);
      
      print('Measurement saved to Supabase successfully');
      return true;
    } catch (e) {
      print('Error saving measurement to Supabase: $e');
      // If Supabase fails, still save locally
      return await _saveToLocal(measurement);
    }
  }

  // Fallback: Save to local storage
  Future<bool> _saveToLocal(MeasurementHistory measurement) async {
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
      print('Error saving measurement locally: $e');
      return false;
    }
  }

  // Delete measurement from Supabase
  Future<bool> deleteMeasurement(String id) async {
    try {
      await supabase
          .from('measurement_history')
          .delete()
          .eq('id', id);
      
      // Also delete from local storage
      await _deleteFromLocal(id);
      
      print('Measurement deleted from Supabase successfully');
      return true;
    } catch (e) {
      print('Error deleting measurement from Supabase: $e');
      // If Supabase fails, still try to delete locally
      return await _deleteFromLocal(id);
    }
  }

  // Fallback: Delete from local storage
  Future<bool> _deleteFromLocal(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      historyJson.removeWhere((jsonStr) {
        final data = json.decode(jsonStr) as Map<String, dynamic>;
        return data['id'] == id;
      });
      
      return await prefs.setStringList(_historyKey, historyJson);
    } catch (e) {
      print('Error deleting measurement locally: $e');
      return false;
    }
  }

  // Clear all history from Supabase
  Future<bool> clearAllHistory() async {
    try {
      // Get current user's data only (if you have user authentication)
      await supabase
          .from('measurement_history')
          .delete()
          .neq('id', ''); // Delete all records
      
      // Also clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      
      print('All history cleared successfully');
      return true;
    } catch (e) {
      print('Error clearing history: $e');
      return false;
    }
  }

  // Get recent history by days
  Future<List<MeasurementHistory>> getRecentHistory(int days) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final data = await supabase
          .from('measurement_history')
          .select()
          .gte('timestamp', cutoffDate.toIso8601String())
          .order('timestamp', ascending: false);
      
      return (data as List)
          .map((item) => MeasurementHistory.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading recent history from Supabase: $e');
      // Fallback to local storage
      final allHistory = await _getLocalHistory();
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      return allHistory.where((m) => m.timestamp.isAfter(cutoffDate)).toList();
    }
  }

  // Get history by date range
  Future<List<MeasurementHistory>> getHistoryByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await supabase
          .from('measurement_history')
          .select()
          .gte('timestamp', startDate.toIso8601String())
          .lte('timestamp', endDate.toIso8601String())
          .order('timestamp', ascending: false);
      
      return (data as List)
          .map((item) => MeasurementHistory.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading history by date range: $e');
      return [];
    }
  }

  // Get average heart rate for a period
  Future<double?> getAverageHeartRate(int days) async {
    try {
      final recentHistory = await getRecentHistory(days);
      if (recentHistory.isEmpty) return null;
      
      final totalHeartRate = recentHistory.fold<int>(
        0,
        (sum, measurement) => sum + measurement.heartRate,
      );
      
      return totalHeartRate / recentHistory.length;
    } catch (e) {
      print('Error calculating average heart rate: $e');
      return null;
    }
  }

  // Get average SpO2 for a period
  Future<double?> getAverageSpO2(int days) async {
    try {
      final recentHistory = await getRecentHistory(days);
      if (recentHistory.isEmpty) return null;
      
      final totalSpO2 = recentHistory.fold<int>(
        0,
        (sum, measurement) => sum + measurement.spO2,
      );
      
      return totalSpO2 / recentHistory.length;
    } catch (e) {
      print('Error calculating average SpO2: $e');
      return null;
    }
  }

  // Sync local data to Supabase (useful for offline mode)
  Future<bool> syncLocalToSupabase() async {
    try {
      final localHistory = await _getLocalHistory();
      
      for (final measurement in localHistory) {
        try {
          // Check if measurement already exists in Supabase
          final existing = await supabase
              .from('measurement_history')
              .select()
              .eq('id', measurement.id)
              .maybeSingle();
          
          if (existing == null) {
            // Insert if doesn't exist
            await supabase.from('measurement_history').insert(measurement.toJson());
          }
        } catch (e) {
          print('Error syncing measurement ${measurement.id}: $e');
        }
      }
      
      print('Local data synced to Supabase successfully');
      return true;
    } catch (e) {
      print('Error syncing local data to Supabase: $e');
      return false;
    }
  }

  // Get statistics summary
  Future<Map<String, dynamic>> getStatisticsSummary(int days) async {
    try {
      final recentHistory = await getRecentHistory(days);
      
      if (recentHistory.isEmpty) {
        return {
          'totalMeasurements': 0,
          'averageHeartRate': 0.0,
          'averageSpO2': 0.0,
          'minHeartRate': 0,
          'maxHeartRate': 0,
          'minSpO2': 0,
          'maxSpO2': 0,
        };
      }
      
      final heartRates = recentHistory.map((m) => m.heartRate).toList();
      final spO2Values = recentHistory.map((m) => m.spO2).toList();
      
      return {
        'totalMeasurements': recentHistory.length,
        'averageHeartRate': heartRates.reduce((a, b) => a + b) / heartRates.length,
        'averageSpO2': spO2Values.reduce((a, b) => a + b) / spO2Values.length,
        'minHeartRate': heartRates.reduce((a, b) => a < b ? a : b),
        'maxHeartRate': heartRates.reduce((a, b) => a > b ? a : b),
        'minSpO2': spO2Values.reduce((a, b) => a < b ? a : b),
        'maxSpO2': spO2Values.reduce((a, b) => a > b ? a : b),
      };
    } catch (e) {
      print('Error calculating statistics: $e');
      return {};
    }
  }
}