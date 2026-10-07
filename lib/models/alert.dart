// ============================================================
// alert.dart - Alert data model
// ============================================================
import 'dart:convert';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum AlertSeverity { warning, critical }

class Alert {
  final String id;
  final AlertSeverity severity;
  final String message;
  final double temperature;
  final DateTime timestamp;
  bool isResolved;

  Alert({
    String? id,
    required this.severity,
    required this.message,
    required this.temperature,
    required this.timestamp,
    this.isResolved = false,
  }) : id = id ?? _uuid.v4();

  String get severityLabel =>
      severity == AlertSeverity.critical ? 'CRITICAL' : 'WARNING';

  factory Alert.fromStatus({
    required String status,
    required double temperature,
  }) {
    final severity = status == 'CRITICAL'
        ? AlertSeverity.critical
        : AlertSeverity.warning;
    final message = status == 'CRITICAL'
        ? 'Temperature has exceeded the configured critical threshold'
        : 'Temperature is approaching the configured critical range';
    return Alert(
      severity: severity,
      message: message,
      temperature: temperature,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'severity': severity.name,
        'message': message,
        'temperature': temperature,
        'timestamp': timestamp.toIso8601String(),
        'isResolved': isResolved,
      };

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String?,
      severity: json['severity'] == 'critical'
          ? AlertSeverity.critical
          : AlertSeverity.warning,
      message: json['message'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isResolved: json['isResolved'] as bool? ?? false,
    );
  }

  static String encodeList(List<Alert> alerts) =>
      jsonEncode(alerts.map((a) => a.toJson()).toList());

  static List<Alert> decodeList(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => Alert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
