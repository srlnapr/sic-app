// ============================================================
// mqtt_service.dart
// MQTT Service - Flutter Web / Chrome
// ============================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

// ============================================================
// MQTT CONNECTION STATUS
// ============================================================

enum MqttConnectionStatus {
  disconnected,
  connecting,
  connected,
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
  MqttBrowserClient? _client;

  String _host;
  int _port;
  String _username;
  String _password;
  String _topic;

  final String _clientId;

  // ==========================================================
  // STATUS
  // ==========================================================

  MqttConnectionStatus _status =
      MqttConnectionStatus.disconnected;

  MqttConnectionStatus get status => _status;

  // ==========================================================
  // STREAM
  // ==========================================================

  final _statusController =
      StreamController<MqttConnectionStatus>.broadcast();

  Stream<MqttConnectionStatus> get statusStream =>
      _statusController.stream;

  final _messageController =
      StreamController<Map<String, String>>.broadcast();

  Stream<Map<String, String>> get messageStream =>
      _messageController.stream;

  // ==========================================================
  // CALLBACK
  // ==========================================================

  MqttMessageCallback? onMessage;

  VoidCallback? onConnected;

  VoidCallback? onDisconnected;

  // ==========================================================
  // RECONNECT
  // ==========================================================

  bool _shouldReconnect = false;

  Timer? _reconnectTimer;

  int _reconnectAttempts = 0;

  StreamSubscription? _updatesSubscription;

  static const int _maxReconnectAttempts = 10;

  static const int _reconnectDelaySeconds = 5;

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
    _host = host ?? _host;

    _port = port ?? _port;

    _username = username ?? _username;

    _password = password ?? _password;

    if (topic != null && topic != _topic) {
      updateTopic(topic);
    }
  }

  // ==========================================================
  // UPDATE TOPIC
  // ==========================================================

  void updateTopic(String newTopic) {
    if (_topic == newTopic) {
      return;
    }

    final oldTopic = _topic;

    _topic = newTopic;

    if (_client != null &&
        _status == MqttConnectionStatus.connected) {
      try {
        _client!.unsubscribe(oldTopic);

        _subscribeToTopic();

        debugPrint(
          'MQTT topic changed:',
        );

        debugPrint(
          'Old topic: $oldTopic',
        );

        debugPrint(
          'New topic: $newTopic',
        );
      } catch (e) {
        debugPrint(
          'MQTT topic switch error: $e',
        );
      }
    }
  }

  // ==========================================================
  // SET STATUS
  // ==========================================================

  void _setStatus(
    MqttConnectionStatus newStatus,
  ) {
    _status = newStatus;

    if (!_statusController.isClosed) {
      _statusController.add(
        newStatus,
      );
    }
  }

  // ==========================================================
  // CONNECT
  // ==========================================================

  Future<void> connect() async {
    if (_status ==
            MqttConnectionStatus.connecting ||
        _status ==
            MqttConnectionStatus.connected) {
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
    _setStatus(
      MqttConnectionStatus.connecting,
    );

    try {
      debugPrint(
        '========================================',
      );

      debugPrint(
        'MQTT CONNECTING',
      );

      debugPrint(
        'Host: $_host',
      );

      debugPrint(
        'Port: $_port',
      );

      debugPrint(
        'Topic: $_topic',
      );

      debugPrint(
        '========================================',
      );

      // Cancel existing reconnect timer & subscriptions
      _reconnectTimer?.cancel();
      _updatesSubscription?.cancel();

      // Disconnect previous instance if any
      try {
        _client?.disconnect();
      } catch (_) {}

      // ------------------------------------------------------
      // CLEAN HOST & RESOLVE WEBSOCKET PARAMETERS FOR CHROME
      // ------------------------------------------------------
      String cleanHost = _host.trim();
      cleanHost = cleanHost.replaceFirst(RegExp(r'^(wss?|https?):\/\/'), '');
      cleanHost = cleanHost.replaceFirst(RegExp(r'\/.*$'), '');
      cleanHost = cleanHost.replaceFirst(RegExp(r':\d+$'), '');

      if (cleanHost.isEmpty || cleanHost.contains('YOUR_HIVEMQ_HOST')) {
        cleanHost = 'broker.hivemq.com';
      }

      int effectivePort = _port;
      // In Flutter Web, standard TCP port 1883 cannot be opened by browser.
      // Use WebSocket port (8000 for public HiveMQ, 8884 for HiveMQ Cloud)
      if (effectivePort == 1883 || effectivePort <= 0) {
        effectivePort = cleanHost.contains('hivemq.cloud') ? 8884 : 8000;
      }

      final bool isSecure = effectivePort == 8884 ||
          effectivePort == 443 ||
          cleanHost.contains('hivemq.cloud');

      final String scheme = isSecure ? 'wss' : 'ws';
      // In browser, MqttBrowserClient requires a URI with ws:// or wss:// scheme
      // and explicit port and path: ws://broker.hivemq.com:8000/mqtt
      final String wsUrl = '$scheme://$cleanHost:$effectivePort/mqtt';

      // Unique client ID using configured clientId prefix (under 23 chars for broker compatibility)
      final String prefix = _clientId.isNotEmpty ? _clientId : 'fg';
      final String cleanPrefix = prefix.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final String shortPrefix =
          cleanPrefix.length > 8 ? cleanPrefix.substring(0, 8) : cleanPrefix;
      final String uniqueId =
          '${shortPrefix}_${DateTime.now().millisecondsSinceEpoch % 1000000}';

      debugPrint('========================================');
      debugPrint('MQTT CONNECTING (Browser WebSocket)');
      debugPrint('Broker Host: $cleanHost');
      debugPrint('Port: $effectivePort');
      debugPrint('WebSocket URI: $wsUrl');
      debugPrint('Client ID: $uniqueId');
      debugPrint('Topic: $_topic');
      debugPrint('========================================');

      _client = MqttBrowserClient.withPort(
        wsUrl,
        uniqueId,
        effectivePort,
      );

      _client!.port = effectivePort;
      _client!.logging(on: false);
      _client!.setProtocolV311();
      _client!.keepAlivePeriod = 60;
      _client!.connectTimeoutPeriod = 10000;
      _client!.websocketProtocols =
          MqttClientConstants.protocolsSingleDefault;

      _client!.onConnected = _onConnectedCallback;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;

      // Clean session connect message without invalid will flags
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(uniqueId)
          .startClean();

      if (_username.trim().isNotEmpty) {
        connMessage.authenticateAs(
          _username.trim(),
          _password.trim(),
        );
      }

      _client!.connectionMessage = connMessage;

      await _client!.connect();

      // ------------------------------------------------------
      // CHECK CONNECTION
      // ------------------------------------------------------
      if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
        _setStatus(MqttConnectionStatus.connected);
        _reconnectAttempts = 0;

        debugPrint('========================================');
        debugPrint('MQTT CONNECTED SUCCESSFULLY (WebSocket)');
        debugPrint('Host: $cleanHost:$effectivePort');
        debugPrint('Primary Topic: $_topic');
        debugPrint('========================================');

        onConnected?.call();
        _listenToMessages();
        _subscribeToTopic();
      } else {
        debugPrint(
          'MQTT connection failed. Status: ${_client!.connectionStatus}',
        );
        _setStatus(MqttConnectionStatus.error);
        _scheduleReconnect();
      }
    } catch (e, stackTrace) {
      debugPrint(
        'MQTT CONNECTION ERROR: $e',
      );
      debugPrint(
        'StackTrace: $stackTrace',
      );
      _setStatus(
        MqttConnectionStatus.error,
      );
      _scheduleReconnect();
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

      final topics = <String>{
        _topic.trim(),
        'fishguard/fsh001/sensor',
        'fishguard/#',
        'fishlogistics/#',
      };

      for (final t in topics) {
        if (t.isNotEmpty) {
          debugPrint('MQTT SUBSCRIBED: $t');
          _client!.subscribe(t, MqttQos.atLeastOnce);
        }
      }
    } catch (e) {
      debugPrint('MQTT subscribe error: $e');
    }
  }

  // ==========================================================
  // LISTEN TO MQTT MESSAGE
  // ==========================================================

  void _listenToMessages() {
    _updatesSubscription?.cancel();
    _updatesSubscription = _client?.updates?.listen(
      (
        List<
            MqttReceivedMessage<
                MqttMessage>> messages,
      ) {
        for (final message in messages) {
          final receivedMessage =
              message.payload
                  as MqttPublishMessage;

          final payload =
              MqttPublishPayload
                  .bytesToStringAsString(
            receivedMessage
                .payload
                .message,
          );

          debugPrint(
            '========================================',
          );

          debugPrint(
            'MQTT MESSAGE RECEIVED',
          );

          debugPrint(
            'Topic: ${message.topic}',
          );

          debugPrint(
            'Payload: $payload',
          );

          debugPrint(
            '========================================',
          );

          // Kirim ke stream
          if (!_messageController
              .isClosed) {
            _messageController.add({
              'topic': message.topic,
              'payload': payload,
            });
          }

          // Callback
          onMessage?.call(
            message.topic,
            payload,
          );
        }
      },
    );
  }

  // ==========================================================
  // ON CONNECTED
  // ==========================================================

  void _onConnectedCallback() {
    debugPrint(
      'MQTT onConnected callback fired',
    );
  }

  // ==========================================================
  // ON DISCONNECTED
  // ==========================================================

  void _onDisconnected() {
    debugPrint(
      'MQTT DISCONNECTED',
    );

    _setStatus(
      MqttConnectionStatus.disconnected,
    );

    onDisconnected?.call();

    _scheduleReconnect();
  }

  // ==========================================================
  // ON SUBSCRIBED
  // ==========================================================

  void _onSubscribed(
    String topic,
  ) {
    debugPrint(
      'MQTT SUBSCRIBED: $topic',
    );
  }

  // ==========================================================
  // RECONNECT
  // ==========================================================

  void _scheduleReconnect() {
    if (!_shouldReconnect) {
      return;
    }

    if (_reconnectAttempts >=
        _maxReconnectAttempts) {
      debugPrint(
        'MQTT max reconnect attempts reached',
      );

      return;
    }

    _reconnectTimer?.cancel();

    final delaySeconds =
        _reconnectDelaySeconds *
            (_reconnectAttempts + 1)
                .clamp(1, 5);

    final delay = Duration(
      seconds: delaySeconds,
    );

    debugPrint(
      'MQTT reconnecting in '
      '${delay.inSeconds}s '
      '(attempt ${_reconnectAttempts + 1})',
    );

    _reconnectTimer = Timer(
      delay,
      () {
        _reconnectAttempts++;

        _doConnect();
      },
    );
  }

  // ==========================================================
  // PUBLISH
  // ==========================================================

  void publish(
    String topic,
    String payload,
  ) {
    if (_client == null ||
        _client!
                .connectionStatus
                ?.state !=
            MqttConnectionState.connected) {
      debugPrint(
        'MQTT not connected, cannot publish',
      );

      return;
    }

    final builder =
        MqttClientPayloadBuilder();

    builder.addString(
      payload,
    );

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
    _updatesSubscription?.cancel();
    _updatesSubscription = null;

    try {
      _client?.disconnect();
    } catch (_) {}

    _setStatus(
      MqttConnectionStatus.disconnected,
    );
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
    _updatesSubscription?.cancel();
    _updatesSubscription = null;

    try {
      _client?.disconnect();
    } catch (_) {}

    _statusController.close();

    _messageController.close();
  }
}