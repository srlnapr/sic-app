import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_client_factory_stub.dart'
    if (dart.library.html) 'mqtt_client_factory_web.dart'
    if (dart.library.io) 'mqtt_client_factory_native.dart';

abstract class MqttClientFactory {
  static MqttClient createClient({
    required String host,
    required int port,
    required String clientId,
  }) {
    return createPlatformClient(
      host: host,
      port: port,
      clientId: clientId,
    );
  }
}
