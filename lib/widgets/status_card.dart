// ============================================================
// status_card.dart - Condition & Alarm status card
// Separates temperature physical status from ESP32 alarm state
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/telemetry_provider.dart';
import '../utils/app_theme.dart';
import '../utils/thresholds.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TelemetryProvider>(
      builder: (context, telemetry, _) {
        final hasData = telemetry.hasReceivedData;
        final tempStatus = hasData ? telemetry.currentStatus : 'WAITING';
        final alarmLevel = telemetry.currentAlarmLevel;
        final isAlarm = telemetry.isAlarmTriggered;
        final isDoorOpen = telemetry.isDoorOpen;
        final isAck = telemetry.isAcknowledged;

        final tempColor = AppColors.statusColor(tempStatus);
        final tempBg = AppColors.statusBgColor(tempStatus);
        final tempBorder = AppColors.statusBorderColor(tempStatus);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: AppTheme.cardDecoration(borderColor: tempBorder),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TEMPERATURE STATUS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (hasData)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tempBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: tempBorder, width: 0.8),
                        ),
                        child: Text(
                          tempStatus,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: tempColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tempBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tempBorder),
                      ),
                      child: Icon(_getTempIcon(tempStatus, hasData),
                          color: tempColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTempTitle(tempStatus, hasData),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tempColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _getTempMessage(tempStatus, hasData),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Separated Alarm Status section
                _buildAlarmStatusRow(
                  hasData: hasData,
                  alarmLevel: alarmLevel,
                  isAlarm: isAlarm,
                  isDoorOpen: isDoorOpen,
                  isAck: isAck,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlarmStatusRow({
    required bool hasData,
    required String alarmLevel,
    required bool isAlarm,
    required bool isDoorOpen,
    required bool isAck,
  }) {
    if (!hasData) {
      return Row(
        children: [
          const Icon(Icons.shield_outlined, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            'Alarm Status: Waiting for telemetry...',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      );
    }

    final bool isDoorFiltered = alarmLevel == 'DOOR_FILTER';
    Color alarmBadgeColor;
    Color alarmBadgeBg;
    String alarmTitle;
    String alarmSubtitle;
    IconData alarmIcon;

    if (isDoorFiltered) {
      alarmBadgeColor = const Color(0xFF2563EB);
      alarmBadgeBg = const Color(0xFFEFF6FF);
      alarmTitle = 'Door Filter Active';
      alarmSubtitle = 'Alarm suppressed while cargo door is open.';
      alarmIcon = Icons.filter_alt_rounded;
    } else if (isAlarm) {
      if (isAck) {
        alarmBadgeColor = const Color(0xFFD97706);
        alarmBadgeBg = const Color(0xFFFEF3C7);
        alarmTitle = 'Alarm Muted (Acknowledged)';
        alarmSubtitle = 'Critical condition acknowledged by operator.';
        alarmIcon = Icons.notifications_paused_rounded;
      } else {
        alarmBadgeColor = AppColors.statusCritical;
        alarmBadgeBg = AppColors.statusCriticalBg;
        alarmTitle = 'Alarm Triggered (Active)';
        alarmSubtitle = 'ESP32 buzzer & alert triggered.';
        alarmIcon = Icons.notifications_active_rounded;
      }
    } else {
      alarmBadgeColor = AppColors.statusNormal;
      alarmBadgeBg = AppColors.statusNormalBg;
      alarmTitle = 'Alarm Inactive (Standby)';
      alarmSubtitle = isDoorOpen
          ? 'Door open, no alarm triggered.'
          : 'Normal operation, buzzer off.';
      alarmIcon = Icons.shield_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: alarmBadgeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alarmBadgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(alarmIcon, size: 16, color: alarmBadgeColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESP32 Alarm: $alarmTitle',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: alarmBadgeColor,
                  ),
                ),
                Text(
                  alarmSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isDoorOpen) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.statusCriticalBorder),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.meeting_room_outlined,
                      size: 11, color: AppColors.statusCritical),
                  SizedBox(width: 3),
                  Text(
                    'DOOR OPEN',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.statusCritical,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTempTitle(String status, bool hasData) {
    if (!hasData) return 'Waiting for Data';
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return 'Normal (${FishThresholds.normalRange})';
      case 'WARNING':
        return 'Warning (${FishThresholds.warningRange})';
      case 'CRITICAL':
        return 'Critical (${FishThresholds.criticalRange})';
      default:
        return 'No Data';
    }
  }

  String _getTempMessage(String status, bool hasData) {
    if (!hasData) {
      return 'Waiting for live MQTT telemetry messages from ESP32...';
    }
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return 'Cargo temperature is in optimal fish cold-chain storage range (< 0°C).';
      case 'WARNING':
        return 'Cargo temperature is approaching critical limits (0°C – 5°C). Monitor closely.';
      case 'CRITICAL':
        return 'Cargo temperature exceeded critical threshold (≥ 5°C)! Quality at risk.';
      default:
        return 'Waiting for active telemetry data...';
    }
  }

  IconData _getTempIcon(String status, bool hasData) {
    if (!hasData) return Icons.hourglass_empty_rounded;
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return Icons.check_circle_rounded;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'CRITICAL':
        return Icons.error_rounded;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }
}
