// ============================================================
// temperature_card.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/telemetry_provider.dart';
import '../utils/app_theme.dart';

class TemperatureCard extends StatelessWidget {
  const TemperatureCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TelemetryProvider>(
      builder: (context, telemetry, _) {
        final status = telemetry.currentStatus;
        final temp = telemetry.currentTemperature;
        final humidity = telemetry.currentHumidity;
        final lastUpdated = telemetry.latest?.timestamp;

        final statusColor = AppColors.statusColor(status);
        final statusBg = AppColors.statusBgColor(status);
        final statusBorder = AppColors.statusBorderColor(status);

        return Container(
          decoration: AppTheme.cardDecoration(borderColor: statusBorder),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CURRENT TEMPERATURE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    _StatusBadge(status: status),
                  ],
                ),
              ),
              // Temperature display
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          temp.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 64,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                            height: 1.0,
                            letterSpacing: -2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            '°C',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: statusColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _getStatusIcon(status),
                          size: 40,
                          color: statusColor.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _MetricChip(
                          icon: Icons.water_drop_outlined,
                          label: 'Humidity',
                          value: '${humidity.toStringAsFixed(0)}%',
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 12),
                        _MetricChip(
                          icon: Icons.access_time_rounded,
                          label: 'Last updated',
                          value: lastUpdated != null
                              ? DateFormat('HH:mm:ss').format(lastUpdated)
                              : '--:--:--',
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return Icons.check_circle_outline_rounded;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'CRITICAL':
        return Icons.error_outline_rounded;
      default:
        return Icons.device_thermostat;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
