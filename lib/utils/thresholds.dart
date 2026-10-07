// ============================================================
// thresholds.dart - Configurable temperature thresholds
// NOTE: These are demo thresholds for the FishGuard IoT project.
// They are NOT universal scientific limits for all fish species.
// Adjust these values based on your specific fish type and
// logistics requirements.
// ============================================================
class FishThresholds {
  // Temperature thresholds (°C)
  // NORMAL: temperature <= normalMax
  // WARNING: normalMax < temperature <= warningMax
  // CRITICAL: temperature > warningMax

  static const double normalMax = 4.0;   // ≤ 4°C = NORMAL
  static const double warningMax = 8.0;  // > 4°C and ≤ 8°C = WARNING
  // > 8°C = CRITICAL

  // Humidity thresholds (%)
  static const double humidityMin = 60.0;
  static const double humidityMax = 90.0;

  // Status labels
  static const String statusNormal = 'NORMAL';
  static const String statusWarning = 'WARNING';
  static const String statusCritical = 'CRITICAL';

  // Y-axis chart range
  static const double chartMinY = -5.0;
  static const double chartMaxY = 15.0;

  /// Compute status from temperature
  static String computeStatus(double temperature) {
    if (temperature <= normalMax) {
      return statusNormal;
    } else if (temperature <= warningMax) {
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
