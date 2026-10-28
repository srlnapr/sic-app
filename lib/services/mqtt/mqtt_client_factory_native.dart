import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createPlatformClient({
  required String host,
  required int port,
  required String clientId,
}) {
  final bool isWebSocket = (port == 8000 || port == 8884 || port == 443);
  final bool isSecure = (port == 8883 ||
      port == 8884 ||
      port == 443 ||
      host.contains('hivemq.cloud'));

  if (isWebSocket) {
    final scheme = isSecure ? 'wss' : 'ws';
    final wsUrl = '$scheme://$host:$port/mqtt';
    final client = MqttServerClient.withPort(
      wsUrl,
      clientId,
      port,
    );
    client.port = port;
    client.useWebSocket = true;
    client.websocketProtocols = MqttClientConstants.protocolsMultipleDefault;
    return client;
  } else {
    final effectivePort = port <= 0 ? (isSecure ? 8883 : 1883) : port;
    final client = MqttServerClient.withPort(
      host,
      clientId,
      effectivePort,
    );
    client.port = effectivePort;
    if (isSecure) {
      client.secure = true;
      client.onBadCertificate = (_) => true;
    }
    return client;
  }
}
