import 'package:flutter_test/flutter_test.dart';
import 'package:fish_guard/models/telemetry_data.dart';
import 'package:fish_guard/utils/thresholds.dart';

void main() {
  group('FishGuard Temperature Threshold & Telemetry Tests', () {
    test('validates threshold rules: NORMAL (<0°C), WARNING (>=0°C and <5°C), CRITICAL (>=5°C)', () {
      // User required test examples:
      // -5°C → NORMAL
      expect(FishThresholds.computeStatus(-5.0), 'NORMAL');
      // 0°C → WARNING
      expect(FishThresholds.computeStatus(0.0), 'WARNING');
      // 2°C → WARNING
      expect(FishThresholds.computeStatus(2.0), 'WARNING');
      // 4.9°C → WARNING
      expect(FishThresholds.computeStatus(4.9), 'WARNING');
      // 5°C → CRITICAL
      expect(FishThresholds.computeStatus(5.0), 'CRITICAL');
      // 7°C → CRITICAL
      expect(FishThresholds.computeStatus(7.0), 'CRITICAL');
    });

    test('parses -5.0°C as NORMAL in standard JSON', () {
      const payload = '{"shipment_id":"FSH001","temperature":-5.0,"humidity":68.0}';
      final data = TelemetryData.fromJsonString(payload);
      expect(data.shipmentId, 'FSH001');
      expect(data.temperature, -5.0);
      expect(data.humidity, 68.0);
      expect(data.status, 'NORMAL');
    });

    test('parses 0.0°C as WARNING in JSON', () {
      const payload = '{"temp":0.0,"hum":75.0}';
      final data = TelemetryData.fromJsonString(payload);
      expect(data.temperature, 0.0);
      expect(data.status, 'WARNING');
    });

    test('parses 2.0°C as WARNING with Wokwi aliases', () {
      const payload = '{"id":"fsh002","temp":2.0,"hum":75.4}';
      final data = TelemetryData.fromJsonString(payload);
      expect(data.shipmentId, 'FSH002');
      expect(data.temperature, 2.0);
      expect(data.status, 'WARNING');
    });

    test('parses 4.9°C as WARNING with Indonesian aliases', () {
      const payload = '{"suhu":"4.9","kelembaban":"82.0"}';
      final data = TelemetryData.fromJsonString(payload, defaultShipmentId: 'FSH001');
      expect(data.shipmentId, 'FSH001');
      expect(data.temperature, 4.9);
      expect(data.humidity, 82.0);
      expect(data.status, 'WARNING');
    });

    test('parses 5.0°C as CRITICAL', () {
      const payload = '{"temp":5.0,"hum":55.0}';
      final data = TelemetryData.fromJsonString(payload);
      expect(data.temperature, 5.0);
      expect(data.status, 'CRITICAL');
    });

    test('parses 7.0°C as CRITICAL', () {
      const payload = '{"temp":7.0,"hum":55.0}';
      final data = TelemetryData.fromJsonString(payload);
      expect(data.temperature, 7.0);
      expect(data.status, 'CRITICAL');
    });

    test('separates temperature status from door filter alarm state (7°C with DOOR_FILTER)', () {
      const payload = '''{
        "shipment_id": "FSH001",
        "temperature": 7.00,
        "humidity": 45.00,
        "door_open": true,
        "alarm": false,
        "alarm_level": "DOOR_FILTER",
        "acknowledged": false
      }''';
      final data = TelemetryData.fromJsonString(payload);
      expect(data.shipmentId, 'FSH001');
      expect(data.temperature, 7.0);
      // Temperature status MUST be CRITICAL because 7.0 >= 5°C
      expect(data.status, 'CRITICAL');
      // Operational alarm state is preserved separately from ESP32
      expect(data.doorOpen, true);
      expect(data.alarm, false);
      expect(data.alarmLevel, 'DOOR_FILTER');
      expect(data.acknowledged, false);
    });

    test('separates temperature status from critical alarm with ACK (7°C with ACK)', () {
      const payload = '''{
        "shipment_id": "FSH001",
        "temperature": 7.00,
        "humidity": 35.00,
        "door_open": false,
        "alarm": true,
        "alarm_level": "CRITICAL",
        "acknowledged": true
      }''';
      final data = TelemetryData.fromJsonString(payload);
      expect(data.shipmentId, 'FSH001');
      expect(data.temperature, 7.0);
      expect(data.status, 'CRITICAL');
      expect(data.doorOpen, false);
      expect(data.alarm, true);
      expect(data.alarmLevel, 'CRITICAL');
      expect(data.acknowledged, true);
    });

    test('parses normal condition with negative temperature and door closed', () {
      const payload = '''{
        "shipment_id": "FSH001",
        "temperature": -2.50,
        "humidity": 40.00,
        "door_open": false,
        "alarm": false,
        "alarm_level": "NORMAL",
        "acknowledged": false
      }''';
      final data = TelemetryData.fromJsonString(payload);
      expect(data.shipmentId, 'FSH001');
      expect(data.temperature, -2.5);
      expect(data.humidity, 40.0);
      expect(data.doorOpen, false);
      expect(data.alarm, false);
      expect(data.alarmLevel, 'NORMAL');
      expect(data.acknowledged, false);
      expect(data.status, 'NORMAL');
    });

    test('parses comma-separated payload: "-1.5, 70.0"', () {
      const payload = '-1.5, 70.0';
      final data = TelemetryData.fromJsonString(payload, defaultShipmentId: 'FSH001');
      expect(data.shipmentId, 'FSH001');
      expect(data.temperature, -1.5);
      expect(data.humidity, 70.0);
      expect(data.status, 'NORMAL');
    });

    test('parses single float payload: "3.2"', () {
      const payload = '3.2';
      final data = TelemetryData.fromJsonString(payload, defaultShipmentId: 'FSH001');
      expect(data.shipmentId, 'FSH001');
      expect(data.temperature, 3.2);
      expect(data.status, 'WARNING');
    });

    test('handles malformed JSON without crashing', () {
      const malformed = '{"shipment_id": "FSH001", "temperature": invalid,';
      final data = TelemetryData.fromJsonString(malformed, defaultShipmentId: 'FSH001');
      expect(data.shipmentId, 'FSH001');
      expect(data.temperature, 4.0);
      expect(data.status, 'WARNING');
    });
  });
}
