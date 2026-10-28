// ============================================================
// thresholds.dart - Configurable temperature thresholds
// Synchronized with Wokwi ESP32 temperature threshold logic:
// - NORMAL:   temperature < 0°C
// - WARNING:  temperature >= 0°C and < 5°C
// - CRITICAL: temperature >= 5°C
// ============================================================

class FishThresholds {
  // Temperature thresholds (°C)
  static const double normalThreshold = 0.0;
  static const double warningThreshold = 5.0;

  // Aliases for compatibility
  static const double normalMax = normalThreshold;
  static const double warningMax = warningThreshold;

  // Status labels
  static const String statusNormal = 'NORMAL';
  static const String statusWarning = 'WARNING';
  static const String statusCritical = 'CRITICAL';
  static const String statusDoorFilter = 'DOOR_FILTER';

  // Range descriptions for consistent UI presentation
  static const String normalRange = '< 0°C';
  static const String warningRange = '≥ 0°C and < 5°C';
  static const String criticalRange = '≥ 5°C';

  static const String normalDetail = 'Optimal temperature (< 0°C)';
  static const String warningDetail = 'Approaching critical range (0°C - 5°C)';
  static const String criticalDetail = 'Immediate action required (≥ 5°C)';

  // Y-axis default chart range for cold-chain sensor (-10°C to 15°C)
  static const double chartMinY = -10.0;
  static const double chartMaxY = 15.0;

  /// Compute status from temperature according to ESP32 rules:
  /// - NORMAL:   temperature < 0°C
  /// - WARNING:  temperature >= 0°C and < 5°C
  /// - CRITICAL: temperature >= 5°C
  static String computeStatus(double temperature) {
    if (temperature < normalThreshold) {
      return statusNormal;
    } else if (temperature < warningThreshold) {
      return statusWarning;
    } else {
      return statusCritical;
    }
  }

  /// Returns true if this status should trigger an alert
  static bool shouldAlert(String status) {
    return status == statusWarning || status == statusCritical;
  }
}
