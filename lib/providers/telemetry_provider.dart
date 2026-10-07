// ============================================================
// telemetry_provider.dart - State management for telemetry data
// ============================================================
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert.dart';
import '../models/telemetry_data.dart';
import '../utils/constants.dart';
import '../utils/thresholds.dart';

class TelemetryProvider extends ChangeNotifier {
  // Current telemetry
  TelemetryData? _latest;
  TelemetryData? get latest => _latest;

  // History (max 100 readings)
  final List<TelemetryData> _history = [];
  List<TelemetryData> get history => List.unmodifiable(_history);

  // Alerts
  final List<Alert> _alerts = [];
  List<Alert> get alerts => List.unmodifiable(_alerts);

  // Demo mode
  bool _isDemoMode = false;
  bool get isDemoMode => _isDemoMode;

  double _demoTemperature = AppConstants.demoDefaultTemperature;
  double get demoTemperature => _demoTemperature;
  set demoTemperature(double v) {
    _demoTemperature = v;
    notifyListeners();
  }

  double _demoHumidity = AppConstants.demoDefaultHumidity;
  double get demoHumidity => _demoHumidity;
  set demoHumidity(double v) {
    _demoHumidity = v;
    notifyListeners();
  }

  Timer? _demoTimer;

  // Stats
  double get currentTemperature => _latest?.temperature ?? 0.0;
  double get currentHumidity => _latest?.humidity ?? 0.0;
  String get currentStatus => _latest?.status ?? 'UNKNOWN';

  double get minTemperature {
    if (_history.isEmpty) return 0.0;
    return _history.map((t) => t.temperature).reduce(math.min);
  }

  double get maxTemperature {
    if (_history.isEmpty) return 0.0;
    return _history.map((t) => t.temperature).reduce(math.max);
  }

  double get avgTemperature {
    if (_history.isEmpty) return 0.0;
    return _history.map((t) => t.temperature).reduce((a, b) => a + b) /
        _history.length;
  }

  // Alert stats
  int get totalAlerts => _alerts.length;
  int get criticalAlerts =>
      _alerts.where((a) => a.severity == AlertSeverity.critical).length;
  int get warningAlerts =>
      _alerts.where((a) => a.severity == AlertSeverity.warning).length;
  int get resolvedAlerts => _alerts.where((a) => a.isResolved).length;

  TelemetryProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDemoMode = prefs.getBool(AppConstants.prefDemoMode) ?? false;
      _demoTemperature =
          prefs.getDouble(AppConstants.prefDemoTemperature) ??
              AppConstants.demoDefaultTemperature;
      _demoHumidity =
          prefs.getDouble(AppConstants.prefDemoHumidity) ??
              AppConstants.demoDefaultHumidity;

      // Load alert history
      final alertJson = prefs.getString(AppConstants.prefAlertHistory);
      if (alertJson != null) {
        final loaded = Alert.decodeList(alertJson);
        _alerts.addAll(loaded.take(AppConstants.maxAlertHistory));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load prefs: $e');
    }
  }

  Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.prefAlertHistory, Alert.encodeList(_alerts));
    } catch (e) {
      debugPrint('Failed to save alerts: $e');
    }
  }

  /// Process incoming telemetry data (from MQTT or demo)
  void processTelemetry(TelemetryData data) {
    _latest = data;
    _history.add(data);
    if (_history.length > AppConstants.maxTelemetryHistory) {
      _history.removeAt(0);
    }

    // Auto-generate alert if status is WARNING/CRITICAL or alarm is triggered
    if (FishThresholds.shouldAlert(data.status) || data.alarm) {
      _addAlertFromTelemetry(data);
    } else {
      // Resolve open alerts when status returns to NORMAL
      _resolveOpenAlerts();
    }

    notifyListeners();
  }

  void _addAlertFromTelemetry(TelemetryData data) {
    // Avoid duplicate alerts: check if latest unresolved alert is same status
    final unresolvedAlerts =
        _alerts.where((a) => !a.isResolved).toList();
    if (unresolvedAlerts.isNotEmpty) {
      final lastAlert = unresolvedAlerts.last;
      final sameSeverity = (data.status == 'CRITICAL' &&
              lastAlert.severity == AlertSeverity.critical) ||
          (data.status == 'WARNING' &&
              lastAlert.severity == AlertSeverity.warning);
      // Allow new alert only if temp changed significantly (>0.5°C)
      final tempDiff =
          (data.temperature - lastAlert.temperature).abs();
      if (sameSeverity && tempDiff < 0.5 && !data.alarm) return;
    }

    final alert = Alert.fromStatus(
      status: data.alarm && data.status == 'NORMAL' ? 'WARNING' : data.status,
      temperature: data.temperature,
    );
    _alerts.insert(0, alert);
    if (_alerts.length > AppConstants.maxAlertHistory) {
      _alerts.removeLast();
    }
    _saveAlerts();
  }

  void _resolveOpenAlerts() {
    bool changed = false;
    for (final alert in _alerts) {
      if (!alert.isResolved) {
        alert.isResolved = true;
        changed = true;
      }
    }
    if (changed) _saveAlerts();
  }

  void resolveAlert(String alertId) {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) {
      _alerts[idx].isResolved = true;
      _saveAlerts();
      notifyListeners();
    }
  }

  void clearAlerts() {
    _alerts.clear();
    _saveAlerts();
    notifyListeners();
  }

  // ─── Demo Mode ───────────────────────────────────────────

  Future<void> setDemoMode(bool enabled) async {
    _isDemoMode = enabled;
    if (enabled) {
      _startDemoTimer();
    } else {
      _stopDemoTimer();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefDemoMode, enabled);
    notifyListeners();
  }

  void _startDemoTimer() {
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(
      const Duration(seconds: AppConstants.demoIntervalSeconds),
      (_) => _generateDemoData(),
    );
    _generateDemoData(); // Immediate first reading
  }

  void _stopDemoTimer() {
    _demoTimer?.cancel();
    _demoTimer = null;
  }

  void _generateDemoData() {
    // Add slight random variation to temperature (±0.3°C) and humidity (±2%)
    final rng = math.Random();
    final variation = (rng.nextDouble() - 0.5) * 0.6;
    final humidVariation = (rng.nextDouble() - 0.5) * 4;
    final temp =
        (_demoTemperature + variation).clamp(-10.0, 30.0);
    final humid =
        (_demoHumidity + humidVariation).clamp(0.0, 100.0);

    processTelemetry(TelemetryData.demo(
      temperature: double.parse(temp.toStringAsFixed(1)),
      humidity: double.parse(humid.toStringAsFixed(1)),
    ));
  }

  void sendDemoData() {
    final temp = _demoTemperature;
    final humid = _demoHumidity;
    processTelemetry(TelemetryData.demo(
      temperature: temp,
      humidity: humid,
    ));
  }

  Future<void> saveDemoSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
        AppConstants.prefDemoTemperature, _demoTemperature);
    await prefs.setDouble(AppConstants.prefDemoHumidity, _demoHumidity);
  }

  @override
  void dispose() {
    _stopDemoTimer();
    super.dispose();
  }
}
