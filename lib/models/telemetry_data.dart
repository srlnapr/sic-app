// ============================================================
// telemetry_data.dart - Telemetry data model
// ============================================================
import 'dart:convert';
import '../utils/thresholds.dart';

class TelemetryData {
  final String shipmentId;
  final double temperature;
  final double humidity;
  final String status;
  final DateTime timestamp;
  final bool alarm;

  const TelemetryData({
    required this.shipmentId,
    required this.temperature,
    required this.humidity,
    required this.status,
    required this.timestamp,
    this.alarm = false,
  });

  static double _parseDouble(dynamic val, [double defaultVal = 0.0]) {
    if (val == null) return defaultVal;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.trim()) ?? defaultVal;
    }
    return defaultVal;
  }

  /// Parse from JSON map (MQTT payload)
  factory TelemetryData.fromJson(Map<String, dynamic> json, {String? defaultShipmentId}) {
    // 1. Temperature: support 'temperature', 'temp', 'suhu', 't', 'val_temp'
    final dynamic rawTemp = json['temperature'] ??
        json['temp'] ??
        json['suhu'] ??
        json['t'] ??
        json['val_temp'];
    final double temp = _parseDouble(rawTemp, 0.0);

    // 2. Humidity: support 'humidity', 'hum', 'kelembaban', 'rh', 'h', 'val_hum'
    final dynamic rawHum = json['humidity'] ??
        json['hum'] ??
        json['kelembaban'] ??
        json['rh'] ??
        json['h'] ??
        json['val_hum'];
    final double hum = _parseDouble(rawHum, 0.0);

    // 3. Status
    final dynamic rawStatusVal = json['status'];
    final String rawStatus = rawStatusVal != null ? rawStatusVal.toString().trim() : '';
    final validStatuses = [
      FishThresholds.statusNormal,
      FishThresholds.statusWarning,
      FishThresholds.statusCritical,
    ];
    final status = validStatuses.contains(rawStatus.toUpperCase())
        ? rawStatus.toUpperCase()
        : FishThresholds.computeStatus(temp);

    // 4. Shipment ID: support 'shipment_id', 'shipmentId', 'id', 'deviceId', 'device_id'
    final dynamic rawShipmentId = json['shipment_id'] ??
        json['shipmentId'] ??
        json['id'] ??
        json['deviceId'] ??
        json['device_id'];
    final String shipmentId = (rawShipmentId != null && rawShipmentId.toString().trim().isNotEmpty)
        ? rawShipmentId.toString().trim().toUpperCase()
        : (defaultShipmentId?.toUpperCase() ?? 'FSH001');

    // 5. Alarm flag
    final dynamic rawAlarm = json['alarm'];
    final bool alarm = rawAlarm is bool
        ? rawAlarm
        : (rawAlarm is num ? rawAlarm != 0 : (rawAlarm?.toString().toLowerCase() == 'true'));

    // 6. Timestamp
    DateTime ts = DateTime.now();
    final dynamic rawTs = json['timestamp'] ?? json['time'] ?? json['ts'];
    if (rawTs != null) {
      if (rawTs is int) {
        ts = rawTs > 1000000000000
            ? DateTime.fromMillisecondsSinceEpoch(rawTs)
            : DateTime.fromMillisecondsSinceEpoch(rawTs * 1000);
      } else if (rawTs is String) {
        ts = DateTime.tryParse(rawTs) ?? DateTime.now();
      }
    }

    return TelemetryData(
      shipmentId: shipmentId,
      temperature: temp,
      humidity: hum,
      status: status,
      timestamp: ts,
      alarm: alarm,
    );
  }

  factory TelemetryData.fromJsonString(String jsonStr, {String? defaultShipmentId}) {
    final trimmed = jsonStr.trim();
    if (trimmed.isEmpty) {
      return TelemetryData.demo(
        temperature: 4.0,
        humidity: 70.0,
        shipmentId: defaultShipmentId ?? 'FSH001',
      );
    }

    // Standard JSON object
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return TelemetryData.fromJson(decoded, defaultShipmentId: defaultShipmentId);
        } else if (decoded is Map) {
          return TelemetryData.fromJson(
            Map<String, dynamic>.from(decoded),
            defaultShipmentId: defaultShipmentId,
          );
        }
      } catch (_) {
        // Fall through to other format checks
      }
    }

    // Handle comma-separated "temp,hum" e.g. "4.2, 68.5"
    if (trimmed.contains(',')) {
      final parts = trimmed.split(',');
      final t = _parseDouble(parts[0], 4.0);
      final h = parts.length > 1 ? _parseDouble(parts[1], 70.0) : 70.0;
      return TelemetryData(
        shipmentId: defaultShipmentId ?? 'FSH001',
        temperature: t,
        humidity: h,
        status: FishThresholds.computeStatus(t),
        timestamp: DateTime.now(),
      );
    }

    // Handle single number e.g. "4.2" (temperature only)
    final singleNum = double.tryParse(trimmed);
    if (singleNum != null) {
      return TelemetryData(
        shipmentId: defaultShipmentId ?? 'FSH001',
        temperature: singleNum,
        humidity: 70.0,
        status: FishThresholds.computeStatus(singleNum),
        timestamp: DateTime.now(),
      );
    }

    // Final attempt with jsonDecode
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        return TelemetryData.fromJson(
          Map<String, dynamic>.from(decoded),
          defaultShipmentId: defaultShipmentId,
        );
      }
    } catch (_) {}

    return TelemetryData.demo(
      temperature: 4.0,
      humidity: 70.0,
      shipmentId: defaultShipmentId ?? 'FSH001',
    );
  }

  Map<String, dynamic> toJson() => {
        'shipment_id': shipmentId,
        'temperature': temperature,
        'humidity': humidity,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'alarm': alarm,
      };

  String toJsonString() => jsonEncode(toJson());

  /// Create a demo/simulated telemetry reading
  factory TelemetryData.demo({
    required double temperature,
    required double humidity,
    String shipmentId = 'FSH001',
    bool alarm = false,
  }) {
    return TelemetryData(
      shipmentId: shipmentId,
      temperature: temperature,
      humidity: humidity,
      status: FishThresholds.computeStatus(temperature),
      timestamp: DateTime.now(),
      alarm: alarm,
    );
  }

  TelemetryData copyWith({
    String? shipmentId,
    double? temperature,
    double? humidity,
    String? status,
    DateTime? timestamp,
    bool? alarm,
  }) {
    return TelemetryData(
      shipmentId: shipmentId ?? this.shipmentId,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      alarm: alarm ?? this.alarm,
    );
  }

  @override
  String toString() =>
      'TelemetryData(shipmentId: $shipmentId, temp: $temperature, '
      'humidity: $humidity, status: $status, alarm: $alarm, ts: $timestamp)';
}
