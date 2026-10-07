import 'package:flutter_test/flutter_test.dart';
import 'package:fish_guard/models/telemetry_data.dart';
import 'package:fish_guard/utils/thresholds.dart';

void main() {
  group('TelemetryData Wokwi parsing tests', () {
    test('parses standard JSON format', () {
      const payload = '{"shipment_id":"FSH001","temperature":3.5,"humidity":68.0,"status":"NORMAL"}';
      final data = TelemetryData.fromJsonString(payload);
      expect(data.shipmentId, 'FSH001');
      expect(data.temperature, 3.5);
      expect(data.humidity, 68.0);
      expect(data.status, FishThresholds.statusNormal);
    });

    test('parses Wokwi aliases: temp, hum, id', () {
      const payload = '{"id":"fsh002","temp":2.1,"hum":75.4}';
      final data = TelemetryData.fromJsonString(payload);
      expect(data.shipmentId, 'FSH002');
      expect(data.temperature, 2.1);
      expect(data.humidity, 75.4);
      expect(data.status, FishThresholds.statusNormal);
    });

    test('parses Indonesian aliases: suhu, kelembaban with string values', () {
      const payload = '{"suhu":"6.8","kelembaban":"82.0"}';
      final data = TelemetryData.fromJsonString(payload, defaultShipmentId: 'FSH001');
      expect(data.shipmentId, 'FSH001');
      expect(data.temperature, 6.8);
      expect(data.humidity, 82.0);
      expect(data.status, FishThresholds.statusWarning);
    });

    test('parses critical temperature and auto computes status', () {
      const payload = '{"temp":11.2,"hum":55.0}';
      final data = TelemetryData.fromJsonString(payload);
      expect(data.temperature, 11.2);
      expect(data.status, FishThresholds.statusCritical);
    });

    test('parses comma-separated payload: "3.2, 70.0"', () {
      const payload = '3.2, 70.0';
      final data = TelemetryData.fromJsonString(payload, defaultShipmentId: 'FSH001');
      expect(data.shipmentId, 'FSH001');
      expect(data.temperature, 3.2);
      expect(data.humidity, 70.0);
      expect(data.status, FishThresholds.statusNormal);
    });

    test('parses single float payload: "4.8"', () {
      const payload = '4.8';
      final data = TelemetryData.fromJsonString(payload, defaultShipmentId: 'FSH001');
      expect(data.shipmentId, 'FSH001');
      expect(data.temperature, 4.8);
      expect(data.humidity, 70.0);
    });

    test('parses exact Wokwi payload with alarm field', () {
      const payload = '{"shipment_id":"FSH001","temperature":24.00,"humidity":40.00,"alarm":false}';
      final data = TelemetryData.fromJsonString(payload);
      expect(data.shipmentId, 'FSH001');
      expect(data.temperature, 24.0);
      expect(data.humidity, 40.0);
      expect(data.alarm, false);
      expect(data.status, FishThresholds.statusCritical); // 24.0°C is > 8.0°C (Critical)
    });
  });
}
