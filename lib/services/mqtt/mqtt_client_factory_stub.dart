import 'package:mqtt_client/mqtt_client.dart';

MqttClient createPlatformClient({
  required String host,
  required int port,
  required String clientId,
}) {
  throw UnsupportedError('MQTT platform client not supported on this platform');
}
