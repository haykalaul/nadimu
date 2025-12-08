import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:nadimu/models/pulseox_data.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? client;
  bool isConnected = false;
  StreamSubscription? _messageSubscription;
  
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
          } catch (e) {
            print('Error parsing pulseox/data: $e');
          }
          break;
        case topicStatus:
          onStatusReceived?.call(payload);
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

