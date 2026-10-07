// ============================================================
// shipment_card.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/shipment.dart';
import '../utils/app_theme.dart';

class ShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final double? temperature;
  final double? humidity;
  final VoidCallback? onTap;
  final VoidCallback? onSetActive;

  const ShipmentCard({
    super.key,
    required this.shipment,
    this.temperature,
    this.humidity,
    this.onTap,
    this.onSetActive,
  });

  @override
  Widget build(BuildContext context) {
    final condColor = AppColors.statusColor(shipment.conditionStatus);
    final condBg = AppColors.statusBgColor(shipment.conditionStatus);
    final isActive = shipment.isActive;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: AppTheme.cardDecoration(
          borderColor:
              isActive ? AppColors.primary : AppColors.divider,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active indicator bar
            if (isActive)
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primarySurface
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          shipment.id,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.statusNormalBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.statusNormalBorder),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sensors_rounded,
                                  size: 11, color: AppColors.statusNormal),
                              SizedBox(width: 3),
                              Text(
                                'TRACKING',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusNormal,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      _ShipmentStatusBadge(status: shipment.shipmentStatus),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    shipment.product,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${shipment.origin} → ${shipment.destination}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Route Progress Bar (for In Transit)
                  if (shipment.shipmentStatus == ShipmentStatus.inTransit) ...[
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              shipment.origin,
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textMuted),
                            ),
                            Text(
                              '${(shipment.progressRatio * 100).toInt()}% Route',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                            Text(
                              shipment.destination,
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: shipment.progressRatio,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.accent),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (isActive && temperature != null) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _TempIndicator(
                          temperature: temperature!,
                          status: shipment.conditionStatus,
                        ),
                        if (humidity != null) ...[
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              const Icon(Icons.water_drop_outlined,
                                  size: 14, color: AppColors.accent),
                              const SizedBox(width: 3),
                              Text(
                                '${humidity!.toStringAsFixed(0)}% RH',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: condBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.statusBorderColor(
                                    shipment.conditionStatus)),
                          ),
                          child: Text(
                            shipment.conditionStatus,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: condColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (!isActive) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          shipment.shipmentStatus == ShipmentStatus.completed
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                          size: 14,
                          color: shipment.shipmentStatus ==
                                  ShipmentStatus.completed
                              ? AppColors.statusNormal
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${shipment.deviceId} • Target: ${shipment.targetTempMin.toStringAsFixed(0)} - ${shipment.targetTempMax.toStringAsFixed(0)}°C',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        if (onSetActive != null)
                          GestureDetector(
                            onTap: onSetActive,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Track',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Tap hint
            if (onTap != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Tap to view details & route timeline',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios,
                        size: 11, color: AppColors.textMuted),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShipmentStatusBadge extends StatelessWidget {
  final String status;
  const _ShipmentStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ShipmentStatus.inTransit:
        color = AppColors.accent;
        break;
      case ShipmentStatus.completed:
        color = AppColors.statusNormal;
        break;
      case ShipmentStatus.delayed:
        color = AppColors.statusCritical;
        break;
      case ShipmentStatus.scheduled:
        color = const Color(0xFF7C3AED);
        break;
      default:
        color = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _TempIndicator extends StatelessWidget {
  final double temperature;
  final String status;
  const _TempIndicator({required this.temperature, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    return Row(
      children: [
        Icon(Icons.device_thermostat, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '${temperature.toStringAsFixed(1)}°C',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
