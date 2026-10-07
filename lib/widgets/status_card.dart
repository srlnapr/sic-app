// ============================================================
// status_card.dart - Condition status card
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/telemetry_provider.dart';
import '../utils/app_theme.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TelemetryProvider>(
      builder: (context, telemetry, _) {
        final status = telemetry.currentStatus;
        final message = _getMessage(status);
        final icon = _getIcon(status);
        final color = AppColors.statusColor(status);
        final bgColor = AppColors.statusBgColor(status);
        final borderColor = AppColors.statusBorderColor(status);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: AppTheme.cardDecoration(borderColor: borderColor),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT CONDITION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTitle(status),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTitle(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return '🟢  Normal';
      case 'WARNING':
        return '🟡  Warning';
      case 'CRITICAL':
        return '🔴  Critical';
      default:
        return '⚪  No Data';
    }
  }

  String _getMessage(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return 'Shipment condition is within the configured monitoring range.';
      case 'WARNING':
        return 'Temperature is approaching the configured critical range.';
      case 'CRITICAL':
        return 'Temperature has exceeded the configured critical threshold.';
      default:
        return 'No telemetry data received yet. Waiting for connection...';
    }
  }

  IconData _getIcon(String status) {
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
