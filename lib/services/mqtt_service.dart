import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:nadimu/models/pulseox_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? client;
  bool isConnected = false;
  StreamSubscription? _messageSubscription;
  
  // Supabase client
  final SupabaseClient supabase = Supabase.instance.client;
  
  // Callbacks
  Function(PulseOxData)? onDataReceived;
  Function(String)? onStatusReceived;
  Function(String)? onHeartRateReceived;
  Function(String)? onSpO2Received;
  Function(bool)? onConnectionChanged;
  final List<void Function(bool)> _connectionListeners = [];

  void addConnectionListener(void Function(bool) listener) {
    _connectionListeners.add(listener);
  }

  void removeConnectionListener(void Function(bool) listener) {
    _connectionListeners.remove(listener);
  }

  void _notifyConnectionChanged(bool connected) {
    onConnectionChanged?.call(connected);
    for (final l in List<void Function(bool)>.from(_connectionListeners)) {
      try {
        l(connected);
      } catch (_) {}
    }
  }

  // Topics
  static const String broker = 'broker.mqtt.cool';
  static const int port = 1883;
  
  String get clientId => 'nadimu_flutter_${DateTime.now().millisecondsSinceEpoch}';
  
  static const String topicData = 'pulseox/data';
  static const String topicStatus = 'pulseox/status';
  static const String topicHeartRate = 'pulseox/heartrate';
  static const String topicSpO2 = 'pulseox/spo2';
  static const String topicCommand = 'pulseox/command';

  Future<bool> connect() async {
    try {
      // Disconnect existing connection if any
      if (client != null && isConnected) {
        disconnect();
      }
      
      client = MqttServerClient.withPort(broker, clientId, port);
      client!.logging(on: false);
      client!.keepAlivePeriod = 20;
      client!.onConnected = onConnected;
      client!.onDisconnected = onDisconnected;
      client!.onSubscribed = onSubscribed;
      client!.onUnsubscribed = onUnsubscribed;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      client!.connectionMessage = connMessage;

      try {
        await client!.connect();
      } catch (e) {
        print('MQTT Connection error: $e');
        client!.disconnect();
        return false;
      }

      if (client!.connectionStatus?.state == MqttConnectionState.connected) {
        print('MQTT Connected to $broker');
        isConnected = true;
        _notifyConnectionChanged(true);
        _subscribeToTopics();
        _setupMessageHandlers();
        return true;
      } else {
        print('MQTT Connection failed');
        isConnected = false;
        _notifyConnectionChanged(false);
        return false;
      }
    } catch (e) {
      print('MQTT Error: $e');
      isConnected = false;
      _notifyConnectionChanged(false);
      return false;
    }
  }

  void _subscribeToTopics() {
    if (client != null && isConnected) {
      client!.subscribe(topicData, MqttQos.atLeastOnce);
      client!.subscribe(topicStatus, MqttQos.atLeastOnce);
      client!.subscribe(topicHeartRate, MqttQos.atLeastOnce);
      client!.subscribe(topicSpO2, MqttQos.atLeastOnce);
      print('Subscribed to all topics');
    }
  }

  void _setupMessageHandlers() {
    // Cancel existing subscription if any
    _messageSubscription?.cancel();
    _messageSubscription = client!.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final topic = c[0].topic;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('Received message: $payload from topic: $topic');

      switch (topic) {
        case topicData:
          try {
            final jsonData = json.decode(payload) as Map<String, dynamic>;
            final data = PulseOxData.fromJson(jsonData);
            onDataReceived?.call(data);
            // Save to Supabase
            _savePulseOxDataToSupabase(data);
          } catch (e) {
            print('Error parsing pulseox/data: $e');
          }
          break;
        case topicStatus:
          onStatusReceived?.call(payload);
          _saveStatusToSupabase(payload);
          break;
        case topicHeartRate:
          onHeartRateReceived?.call(payload);
          break;
        case topicSpO2:
          onSpO2Received?.call(payload);
          break;
      }
    });
  }
  
  // Save PulseOx data to Supabase
  Future<void> _savePulseOxDataToSupabase(PulseOxData data) async {
    try {
      await supabase.from('pulseox_data').insert({
        'heart_rate': data.heartRate,
        'spo2': data.spO2,
        'timestamp': data.timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'device_id': clientId,
      });
      print('PulseOx data saved to Supabase');
    } catch (e) {
      print('Error saving PulseOx data to Supabase: $e');
    }
  }
  
  // Save status to Supabase
  Future<void> _saveStatusToSupabase(String status) async {
    try {
      await supabase.from('pulseox_status').insert({
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
        'device_id': clientId,
      });
      print('Status saved to Supabase');
    } catch (e) {
      print('Error saving status to Supabase: $e');
    }
  }
  
  // Fetch all PulseOx data from Supabase
  Future<List<Map<String, dynamic>>> fetchPulseOxData() async {
    try {
      final data = await supabase
          .from('pulseox_data')
          .select()
          .order('timestamp', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching PulseOx data from Supabase: $e');
      return [];
    }
  }
  
  // Fetch PulseOx data by date range
  Future<List<Map<String, dynamic>>> fetchPulseOxDataByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await supabase
          .from('pulseox_data')
          .select()
          .gte('timestamp', startDate.toIso8601String())
          .lte('timestamp', endDate.toIso8601String())
          .order('timestamp', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching PulseOx data by date range: $e');
      return [];
    }
  }
  
  // Fetch latest PulseOx data
  Future<Map<String, dynamic>?> fetchLatestPulseOxData() async {
    try {
      final data = await supabase
          .from('pulseox_data')
          .select()
          .order('timestamp', ascending: false)
          .limit(1)
          .single();
      return data;
    } catch (e) {
      print('Error fetching latest PulseOx data: $e');
      return null;
    }
  }
  
  // Fetch all status logs
  Future<List<Map<String, dynamic>>> fetchStatusLogs() async {
    try {
      final data = await supabase
          .from('pulseox_status')
          .select()
          .order('timestamp', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching status logs from Supabase: $e');
      return [];
    }
  }
  
  // Delete old data (older than specified days)
  Future<void> deleteOldData(int daysToKeep) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      await supabase
          .from('pulseox_data')
          .delete()
          .lt('timestamp', cutoffDate.toIso8601String());
      
      await supabase
          .from('pulseox_status')
          .delete()
          .lt('timestamp', cutoffDate.toIso8601String());
      
      print('Old data deleted successfully');
    } catch (e) {
      print('Error deleting old data: $e');
    }
  }

  void ensureMessageHandlers() {
    if (client != null && isConnected && _messageSubscription == null) {
      _setupMessageHandlers();
    }
  }

  void onConnected() {
    print('MQTT Client connected');
  }

  void onDisconnected() {
    print('MQTT Client disconnected');
    isConnected = false;
    _notifyConnectionChanged(false);
  }

  void onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void onUnsubscribed(String? topic) {
    print('Unsubscribed from topic: $topic');
  }

  Future<bool> publishCommand(String command) async {
    if (client != null && isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(command);
      client!.publishMessage(topicCommand, MqttQos.atLeastOnce, builder.payload!);
      print('Published command: $command to $topicCommand');
      return true;
    }
    print('Cannot publish: Not connected');
    return false;
  }

  void disconnect() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    if (client != null) {
      client!.disconnect();
      isConnected = false;
      _notifyConnectionChanged(false);
    }
  }
}