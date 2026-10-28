import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient createPlatformClient({
  required String host,
  required int port,
  required String clientId,
}) {
  int effectivePort = port;
  if (effectivePort == 1883 || effectivePort <= 0) {
    effectivePort = host.contains('hivemq.cloud') ? 8884 : 8000;
  }

  bool isHttps = false;
  try {
    isHttps = Uri.base.scheme == 'https';
  } catch (_) {}

  final bool isSecure = isHttps ||
      effectivePort == 8884 ||
      effectivePort == 443 ||
      host.contains('hivemq.cloud');

  if (isSecure && effectivePort == 8000) {
    effectivePort = 8884;
  }

  final scheme = isSecure ? 'wss' : 'ws';
  final wsUrl = '$scheme://$host:$effectivePort/mqtt';

  final client = MqttBrowserClient.withPort(
    wsUrl,
    clientId,
    effectivePort,
  );
  client.port = effectivePort;
  client.websocketProtocols = MqttClientConstants.protocolsMultipleDefault;
  return client;
}
