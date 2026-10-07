// ============================================================
// mqtt_provider.dart - MQTT connection state management
// ============================================================
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/mqtt_service.dart';
import '../models/telemetry_data.dart';
import '../utils/constants.dart';
import 'telemetry_provider.dart';

class MqttProvider extends ChangeNotifier {
  late MqttService _mqttService;
  late TelemetryProvider _telemetryProvider;
  StreamSubscription<MqttConnectionStatus>? _statusSubscription;
  bool _disposed = false;

  MqttConnectionStatus _connectionStatus = MqttConnectionStatus.disconnected;
  MqttConnectionStatus get connectionStatus => _connectionStatus;

  String _host = AppConstants.mqttHost;
  String get host => _host;

  int _port = AppConstants.mqttPort;
  int get port => _port;

  String _username = AppConstants.mqttUsername;
  String get username => _username;

  String _password = AppConstants.mqttPassword;
  String get password => _password;

  String _topic = AppConstants.mqttTopic;
  String get topic => _topic;

  String? _lastError;
  String? get lastError => _lastError;

  MqttProvider(TelemetryProvider telemetryProvider) {
    _telemetryProvider = telemetryProvider;
    _mqttService = MqttService(
      host: _host,
      port: _port,
      username: _username,
      password: _password,
      topic: _topic,
      clientId: AppConstants.mqttClientId,
    );

    _statusSubscription = _mqttService.statusStream.listen((status) {
      if (!_disposed) {
        _connectionStatus = status;
        notifyListeners();
      }
    });

    _mqttService.onMessage = _handleMessage;

    _loadConfig();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var host = prefs.getString(AppConstants.prefMqttHost) ?? _host;
      if (host.contains('YOUR_HIVEMQ_HOST') || host.trim().isEmpty) {
        host = AppConstants.mqttHost;
        await prefs.setString(AppConstants.prefMqttHost, host);
      }
      _host = host;

      var port = prefs.getInt(AppConstants.prefMqttPort) ?? _port;
      // In web browser, HiveMQ public broker uses WebSocket port 8000
      if (_host == 'broker.hivemq.com' && (port == 1883 || port == 8884)) {
        port = 8000;
        await prefs.setInt(AppConstants.prefMqttPort, port);
      }
      _port = port;

      var username = prefs.getString(AppConstants.prefMqttUsername) ?? _username;
      if (username.contains('YOUR_MQTT_USERNAME')) {
        username = '';
        await prefs.setString(AppConstants.prefMqttUsername, username);
      }
      _username = username;

      var password = prefs.getString(AppConstants.prefMqttPassword) ?? _password;
      if (password.contains('YOUR_MQTT_PASSWORD')) {
        password = '';
        await prefs.setString(AppConstants.prefMqttPassword, password);
      }
      _password = password;

      var topic = prefs.getString(AppConstants.prefMqttTopic) ?? _topic;
      if (topic.trim().isEmpty) {
        topic = AppConstants.mqttTopic;
        await prefs.setString(AppConstants.prefMqttTopic, topic);
      }
      _topic = topic;

      _mqttService.updateConfig(
        host: _host,
        port: _port,
        username: _username,
        password: _password,
        topic: _topic,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load MQTT config: $e');
    }
  }

  Future<void> saveConfig({
    required String host,
    required int port,
    required String username,
    required String password,
    required String topic,
  }) async {
    _host = host;
    _port = port;
    _username = username;
    _password = password;
    _topic = topic;

    _mqttService.updateConfig(
      host: host,
      port: port,
      username: username,
      password: password,
      topic: topic,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefMqttHost, host);
      await prefs.setInt(AppConstants.prefMqttPort, port);
      await prefs.setString(AppConstants.prefMqttUsername, username);
      await prefs.setString(AppConstants.prefMqttPassword, password);
      await prefs.setString(AppConstants.prefMqttTopic, topic);
    } catch (e) {
      debugPrint('Failed to save MQTT config: $e');
    }
    notifyListeners();
  }

  /// Switch telemetry topic dynamically (e.g. when user switches active shipment)
  Future<void> switchTopic(String newTopic) async {
    if (_topic == newTopic) return;
    _topic = newTopic;
    _mqttService.updateTopic(newTopic);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefMqttTopic, newTopic);
    } catch (e) {
      debugPrint('Failed to persist switched topic: $e');
    }
    notifyListeners();
  }

  void _handleMessage(String topic, String payload) {
    try {
      String? derivedShipmentId;
      final parts = topic.split('/');
      for (final p in parts) {
        if (p.toUpperCase().startsWith('FSH')) {
          derivedShipmentId = p.toUpperCase();
          break;
        }
      }
      if (derivedShipmentId == null && parts.length >= 2) {
        final candidate = parts[1].toUpperCase();
        if (candidate != 'SENSOR' && candidate != 'TELEMETRY' && candidate != '+') {
          derivedShipmentId = candidate;
        }
      }

      final data = TelemetryData.fromJsonString(
        payload,
        defaultShipmentId: derivedShipmentId,
      );
      _telemetryProvider.processTelemetry(data);
      _lastError = null;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to parse MQTT message: $e';
      debugPrint('MQTT parse error: $e\nPayload: $payload');
      notifyListeners();
    }
  }

  Future<void> connect() async {
    if (_telemetryProvider.isDemoMode) return;
    _lastError = null;
    notifyListeners();
    try {
      await _mqttService.connect();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _mqttService.disconnect();
  }

  Future<void> reconnect() async {
    _lastError = null;
    notifyListeners();
    await _mqttService.reconnect();
  }

  String get statusLabel {
    switch (_connectionStatus) {
      case MqttConnectionStatus.connected:
        return 'CONNECTED';
      case MqttConnectionStatus.connecting:
        return 'CONNECTING';
      case MqttConnectionStatus.disconnected:
        return 'DISCONNECTED';
      case MqttConnectionStatus.error:
        return 'ERROR';
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _statusSubscription?.cancel();
    _mqttService.dispose();
    super.dispose();
  }
}
