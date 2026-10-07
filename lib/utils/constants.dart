// ============================================================
// constants.dart - App-wide constants
// ============================================================
class AppConstants {
  // App Info
  static const String appName = 'FishGuard';
  static const String appTagline = 'Smart Monitoring for Safer Fish Logistics';
  static const String appVersion = '1.0.0';

  // Default Shipment Info
  static const String defaultShipmentId = 'FSH001';
  static const String defaultProduct = 'Fresh Fish';
  static const String defaultOrigin = 'Cilacap';
  static const String defaultDestination = 'Jakarta';
  static const String defaultDeviceId = 'ESP32-FSH001';
  static const String defaultSensor = 'DHT22';

  // MQTT Default Config (Compatible with Wokwi ESP32 & HiveMQ Public Broker)
  static const String mqttHost = 'broker.hivemq.com';
  static const int mqttPort = 8000; // WebSocket for Flutter Web / Chrome
  static const String mqttUsername = '';
  static const String mqttPassword = '';
  static const String mqttTopic = 'fishguard/fsh001/sensor';
  static const String mqttClientId = 'fishguard_web_client';

  // Demo Mode
  static const int demoIntervalSeconds = 3;
  static const double demoDefaultTemperature = 4.0;
  static const double demoDefaultHumidity = 70.0;

  // History
  static const int maxTelemetryHistory = 100;
  static const int maxAlertHistory = 50;

  // SharedPreferences Keys
  static const String prefMqttHost = 'mqtt_host';
  static const String prefMqttPort = 'mqtt_port';
  static const String prefMqttUsername = 'mqtt_username';
  static const String prefMqttPassword = 'mqtt_password';
  static const String prefMqttTopic = 'mqtt_topic';
  static const String prefDemoMode = 'demo_mode';
  static const String prefDemoTemperature = 'demo_temperature';
  static const String prefDemoHumidity = 'demo_humidity';
  static const String prefAlertHistory = 'alert_history';
}
