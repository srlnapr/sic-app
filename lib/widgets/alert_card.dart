// ============================================================
// alert_card.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';
import '../utils/app_theme.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onResolve;

  const AlertCard({super.key, required this.alert, this.onResolve});

  @override
  Widget build(BuildContext context) {
    final isCritical = alert.severity == AlertSeverity.critical;
    final color = isCritical ? AppColors.statusCritical : AppColors.statusWarning;
    final bgColor = isCritical ? AppColors.statusCriticalBg : AppColors.statusWarningBg;
    final borderColor =
        isCritical ? AppColors.statusCriticalBorder : AppColors.statusWarningBorder;

    return Container(
      decoration: AppTheme.cardDecoration(borderColor: borderColor),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                isCritical ? Icons.error_rounded : Icons.warning_amber_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isCritical ? 'CRITICAL' : 'WARNING',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('HH:mm').format(alert.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alert.message,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.device_thermostat,
                          size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        '${alert.temperature.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd MMM yyyy').format(alert.timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      if (alert.isResolved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.statusNormalBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.statusNormalBorder),
                          ),
                          child: const Text(
                            'Resolved',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.statusNormal,
                            ),
                          ),
                        )
                      else if (onResolve != null)
                        GestureDetector(
                          onTap: onResolve,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: const Text(
                              'Resolve',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
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
