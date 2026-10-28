// ============================================================
// mqtt_service.dart
// MQTT Service - Flutter Web / Chrome (WebSocket-compatible)
// ============================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt/mqtt_client_factory.dart';

// ============================================================
// MQTT CONNECTION STATUS
// ============================================================

enum MqttConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

// ============================================================
// MESSAGE CALLBACK
// ============================================================

typedef MqttMessageCallback = void Function(
  String topic,
  String payload,
);

// ============================================================
// MQTT SERVICE
// ============================================================

class MqttService {
  MqttClient? _client;

  String _host;
  int _port;
  String _username;
  String _password;
  String _topic;

  final String _clientId;

  // ==========================================================
  // STATUS
  // ==========================================================

  MqttConnectionStatus _status = MqttConnectionStatus.disconnected;
  MqttConnectionStatus get status => _status;

  // ==========================================================
  // STREAM CONTROLLERS
  // ==========================================================

  final _statusController = StreamController<MqttConnectionStatus>.broadcast();
  Stream<MqttConnectionStatus> get statusStream => _statusController.stream;

  final _messageController = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get messageStream => _messageController.stream;

  // ==========================================================
  // CALLBACKS
  // ==========================================================

  MqttMessageCallback? onMessage;
  VoidCallback? onConnected;
  VoidCallback? onDisconnected;

  // ==========================================================
  // RECONNECT & CONCURRENCY CONTROL
  // ==========================================================

  bool _shouldReconnect = true;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  StreamSubscription? _updatesSubscription;
  final Set<String> _subscribedTopics = {};

  static const int _maxReconnectAttempts = 15;
  static const int _baseReconnectDelaySeconds = 3;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  MqttService({
    required String host,
    required int port,
    required String username,
    required String password,
    required String topic,
    required String clientId,
  })  : _host = host,
        _port = port,
        _username = username,
        _password = password,
        _topic = topic,
        _clientId = clientId;

  // ==========================================================
  // UPDATE CONFIG
  // ==========================================================

  void updateConfig({
    String? host,
    int? port,
    String? username,
    String? password,
    String? topic,
  }) {
    final bool hostChanged = host != null && host != _host;
    final bool portChanged = port != null && port != _port;
    final bool credentialsChanged =
        (username != null && username != _username) ||
        (password != null && password != _password);

    _host = host ?? _host;
    _port = port ?? _port;
    _username = username ?? _username;
    _password = password ?? _password;

    if (topic != null && topic != _topic) {
      updateTopic(topic);
    }

    // Reconnect if core connection details changed and currently connected
    if ((hostChanged || portChanged || credentialsChanged) &&
        _status == MqttConnectionStatus.connected) {
      reconnect();
    }
  }

  // ==========================================================
  // UPDATE TOPIC
  // ==========================================================

  void updateTopic(String newTopic) {
    final cleanNew = newTopic.trim();
    if (cleanNew.isEmpty || cleanNew == _topic) {
      return;
    }

    final oldTopic = _topic;
    _topic = cleanNew;

    if (_client != null && _status == MqttConnectionStatus.connected) {
      try {
        if (_subscribedTopics.contains(oldTopic) && oldTopic != _topic) {
          _client!.unsubscribe(oldTopic);
          _subscribedTopics.remove(oldTopic);
        }
        _subscribeToTopic();
        debugPrint('MQTT topic switched from $oldTopic to $_topic');
      } catch (e) {
        debugPrint('MQTT topic switch error: $e');
      }
    }
  }

  // ==========================================================
  // SET STATUS
  // ==========================================================

  void _setStatus(MqttConnectionStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }

  // ==========================================================
  // CONNECT
  // ==========================================================

  Future<void> connect() async {
    if (_status == MqttConnectionStatus.connecting ||
        _status == MqttConnectionStatus.connected ||
        _isConnecting) {
      debugPrint('MQTT connect called, but already connecting or connected.');
      return;
    }

    _shouldReconnect = true;
    _reconnectAttempts = 0;
    await _doConnect();
  }

  // ==========================================================
  // DO CONNECT
  // ==========================================================

  Future<void> _doConnect() async {
    if (_isConnecting) return;
    _isConnecting = true;

    // Cancel pending reconnect timer
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_status != MqttConnectionStatus.reconnecting) {
      _setStatus(MqttConnectionStatus.connecting);
    }

    // Safely tear down previous client without triggering old disconnect callbacks
    _teardownClient();

    try {
      // ------------------------------------------------------
      // PARSE HOST & PORT
      // ------------------------------------------------------
      String cleanHost = _host.trim();
      cleanHost = cleanHost.replaceFirst(RegExp(r'^(wss?|https?):\/\/'), '');
      cleanHost = cleanHost.replaceFirst(RegExp(r'\/.*$'), '');
      cleanHost = cleanHost.replaceFirst(RegExp(r':\d+$'), '');

      if (cleanHost.isEmpty || cleanHost.contains('YOUR_HIVEMQ_HOST')) {
        cleanHost = 'broker.hivemq.com';
      }

      int effectivePort = _port;
      if (kIsWeb) {
        // In Flutter Web, standard TCP port 1883 cannot be opened by browser.
        // Convert to WebSocket ports: 8000 for HiveMQ public (or 8884 for TLS)
        if (effectivePort == 1883 || effectivePort <= 0) {
          effectivePort = cleanHost.contains('hivemq.cloud') ? 8884 : 8000;
        }
      } else {
        // Native mobile / desktop
        if (effectivePort <= 0) {
          effectivePort = cleanHost.contains('hivemq.cloud') ? 8883 : 1883;
        }
      }

      // Unique client ID (under 23 characters for broker compatibility)
      final String prefix = _clientId.isNotEmpty ? _clientId : 'fg';
      final String cleanPrefix = prefix.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final String shortPrefix =
          cleanPrefix.length > 8 ? cleanPrefix.substring(0, 8) : cleanPrefix;
      final String uniqueId =
          '${shortPrefix}_${DateTime.now().millisecondsSinceEpoch % 1000000}';

      debugPrint('========================================');
      debugPrint('MQTT CONNECTING (${kIsWeb ? "Web WebSocket" : "Mobile/Native TCP/WS"})');
      debugPrint('Broker Host: $cleanHost');
      debugPrint('Port: $effectivePort');
      debugPrint('Client ID: $uniqueId');
      debugPrint('Target Topic: $_topic');
      debugPrint('========================================');

      final client = MqttClientFactory.createClient(
        host: cleanHost,
        port: effectivePort,
        clientId: uniqueId,
      );

      client.logging(on: false);
      client.setProtocolV311();
      client.keepAlivePeriod = 60;
      client.connectTimeoutPeriod = 8000;

      client.onConnected = _onConnectedCallback;
      client.onDisconnected = _onDisconnected;
      client.onSubscribed = _onSubscribed;

      // Clean session connect message
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(uniqueId)
          .startClean();

      if (_username.trim().isNotEmpty) {
        connMessage.authenticateAs(
          _username.trim(),
          _password.trim(),
        );
      }

      client.connectionMessage = connMessage;
      _client = client;

      await client.connect();

      // ------------------------------------------------------
      // CHECK CONNECTION STATUS
      // ------------------------------------------------------
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        _isConnecting = false;
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        _setStatus(MqttConnectionStatus.connected);

        debugPrint('========================================');
        debugPrint('MQTT CONNECTED SUCCESSFULLY (WebSocket)');
        debugPrint('Host: $cleanHost:$effectivePort');
        debugPrint('Primary Topic: $_topic');
        debugPrint('========================================');

        onConnected?.call();
        _listenToMessages();
        _subscribeToTopic();
      } else {
        _isConnecting = false;
        debugPrint('MQTT connection failed. Status: ${client.connectionStatus}');
        _setStatus(MqttConnectionStatus.error);
        _scheduleReconnect();
      }
    } catch (e, stackTrace) {
      _isConnecting = false;
      debugPrint('MQTT CONNECTION ERROR: $e');
      debugPrint('StackTrace: $stackTrace');
      _setStatus(MqttConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  void _teardownClient() {
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    _subscribedTopics.clear();

    if (_client != null) {
      try {
        _client!.onDisconnected = null;
        _client!.onConnected = null;
        _client!.onSubscribed = null;
        _client!.disconnect();
      } catch (_) {}
      _client = null;
    }
  }

  // ==========================================================
  // SUBSCRIBE
  // ==========================================================

  void _subscribeToTopic() {
    try {
      if (_client == null || _status != MqttConnectionStatus.connected) {
        return;
      }

      final targetTopic = _topic.trim();
      final topicsToSubscribe = <String>{
        if (targetTopic.isNotEmpty) targetTopic,
        'fishguard/fsh001/sensor',
      };

      for (final t in topicsToSubscribe) {
        if (!_subscribedTopics.contains(t)) {
          debugPrint('MQTT SUBSCRIBING: $t');
          _client!.subscribe(t, MqttQos.atLeastOnce);
          _subscribedTopics.add(t);
        }
      }
    } catch (e) {
      debugPrint('MQTT subscribe error: $e');
    }
  }

  // ==========================================================
  // LISTEN TO MQTT MESSAGES
  // ==========================================================

  void _listenToMessages() {
    _updatesSubscription?.cancel();
    _updatesSubscription = _client?.updates?.listen(
      (List<MqttReceivedMessage<MqttMessage>> messages) {
        for (final message in messages) {
          try {
            final receivedMessage = message.payload as MqttPublishMessage;
            final payload = MqttPublishPayload.bytesToStringAsString(
              receivedMessage.payload.message,
            );

            debugPrint('MQTT MESSAGE RECEIVED on ${message.topic}: $payload');

            // Send to broadcast stream
            if (!_messageController.isClosed) {
              _messageController.add({
                'topic': message.topic,
                'payload': payload,
              });
            }

            // Callback
            onMessage?.call(message.topic, payload);
          } catch (e) {
            debugPrint('Error processing incoming MQTT message: $e');
          }
        }
      },
      onError: (err) {
        debugPrint('MQTT message stream error: $err');
      },
    );
  }

  // ==========================================================
  // CALLBACK HANDLERS
  // ==========================================================

  void _onConnectedCallback() {
    debugPrint('MQTT onConnected callback fired');
  }

  void _onDisconnected() {
    debugPrint('MQTT onDisconnected callback fired from broker');
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    _subscribedTopics.clear();

    if (_status != MqttConnectionStatus.disconnected &&
        _status != MqttConnectionStatus.reconnecting) {
      _setStatus(MqttConnectionStatus.disconnected);
    }

    onDisconnected?.call();

    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  void _onSubscribed(String topic) {
    debugPrint('MQTT SUBSCRIPTION CONFIRMED: $topic');
    _subscribedTopics.add(topic);
  }

  // ==========================================================
  // RECONNECT WITH EXPONENTIAL BACKOFF
  // ==========================================================

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('MQTT max reconnect attempts reached ($_maxReconnectAttempts).');
      _setStatus(MqttConnectionStatus.disconnected);
      return;
    }

    _reconnectTimer?.cancel();
    _setStatus(MqttConnectionStatus.reconnecting);

    // Exponential backoff: 3s, 5s, 8s, 12s, up to 30s
    final int delaySeconds = (_baseReconnectDelaySeconds *
            math.pow(1.4, _reconnectAttempts).toInt())
        .clamp(3, 30);
    final delay = Duration(seconds: delaySeconds);

    debugPrint('MQTT reconnect scheduled in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _doConnect();
    });
  }

  // ==========================================================
  // PUBLISH
  // ==========================================================

  void publish(String topic, String payload) {
    if (_client == null ||
        _client!.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('MQTT not connected, cannot publish');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    _client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  // ==========================================================
  // DISCONNECT
  // ==========================================================

  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isConnecting = false;

    _teardownClient();
    _setStatus(MqttConnectionStatus.disconnected);
  }

  // ==========================================================
  // RECONNECT MANUALLY
  // ==========================================================

  Future<void> reconnect() async {
    await disconnect();
    _shouldReconnect = true;
    _reconnectAttempts = 0;
    await _doConnect();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  void dispose() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isConnecting = false;

    _teardownClient();

    _statusController.close();
    _messageController.close();
  }
}