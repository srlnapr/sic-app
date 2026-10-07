// ============================================================
// home_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/shipment.dart';
import '../../providers/mqtt_provider.dart';
import '../../providers/shipment_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../services/mqtt_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/mqtt_status_indicator.dart';
import '../../widgets/status_card.dart';
import '../../widgets/temperature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Logo icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.set_meal_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppConstants.appName,
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  AppConstants.appTagline,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const MqttStatusIndicator(compact: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Demo mode banner
                Consumer<TelemetryProvider>(
                  builder: (context, telemetry, _) {
                    if (!telemetry.isDemoMode) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.science_outlined,
                              color: Color(0xFF7C3AED), size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'DEMO MODE ACTIVE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7C3AED),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Simulated data',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // MQTT disconnected warning
                Consumer2<MqttProvider, TelemetryProvider>(
                  builder: (context, mqtt, telemetry, _) {
                    if (telemetry.isDemoMode) return const SizedBox.shrink();
                    if (mqtt.connectionStatus ==
                        MqttConnectionStatus.connected) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.statusCriticalBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.statusCriticalBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              color: AppColors.statusCritical, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'MQTT Disconnected — Last data may be outdated',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.statusCritical,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => mqtt.reconnect(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.statusCritical,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Reconnect',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Main shipment card
                Consumer<ShipmentProvider>(
                  builder: (context, shipmentProvider, _) {
                    final shipment = shipmentProvider.activeShipment;
                    if (shipment == null) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration(),
                        child: const Text('No active shipment.'),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'ACTIVE SHIPMENT',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _openShipmentSwitcher(
                                    context, shipmentProvider),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.swap_horiz_rounded,
                                          size: 14, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Switch',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _InfoRow(
                                        label: 'Shipment ID',
                                        value: shipment.id),
                                    const SizedBox(height: 8),
                                    _InfoRow(
                                        label: 'Product',
                                        value: shipment.product),
                                    const SizedBox(height: 8),
                                    _InfoRow(
                                      label: 'Route',
                                      value:
                                          '${shipment.origin} → ${shipment.destination}',
                                    ),
                                    if (shipment.driverName != null) ...[
                                      const SizedBox(height: 8),
                                      _InfoRow(
                                        label: 'Driver',
                                        value: shipment.driverName!,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.local_shipping_outlined,
                                        color: AppColors.accent, size: 20),
                                    const SizedBox(height: 4),
                                    Text(
                                      shipment.shipmentStatus,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (shipment.shipmentStatus ==
                              ShipmentStatus.inTransit) ...[
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: shipment.progressRatio,
                                backgroundColor: AppColors.surfaceVariant,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.accent),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Temperature card
                const TemperatureCard(),
                const SizedBox(height: 12),

                // Status card
                const StatusCard(),
                const SizedBox(height: 12),

                // Quick stats
                Consumer<TelemetryProvider>(
                  builder: (context, telemetry, _) {
                    return Row(
                      children: [
                        _QuickStatCard(
                          label: 'Min Temp',
                          value: telemetry.history.isEmpty
                              ? '--'
                              : '${telemetry.minTemperature.toStringAsFixed(1)}°C',
                          icon: Icons.arrow_downward_rounded,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        _QuickStatCard(
                          label: 'Max Temp',
                          value: telemetry.history.isEmpty
                              ? '--'
                              : '${telemetry.maxTemperature.toStringAsFixed(1)}°C',
                          icon: Icons.arrow_upward_rounded,
                          color: AppColors.statusCritical,
                        ),
                        const SizedBox(width: 8),
                        _QuickStatCard(
                          label: 'Readings',
                          value: '${telemetry.history.length}',
                          icon: Icons.data_usage_rounded,
                          color: AppColors.statusNormal,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openShipmentSwitcher(
      BuildContext context, ShipmentProvider shipmentProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final all = shipmentProvider.allShipments;
        final currentId = shipmentProvider.activeShipmentId;

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Select Active Shipment',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Switching active shipment automatically updates live MQTT topic tracking.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: all.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final item = all[i];
                    final isCur = item.id == currentId;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCur
                              ? AppColors.primarySurface
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.local_shipping_outlined,
                          color: isCur
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${item.id} • ${item.product}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isCur ? FontWeight.w700 : FontWeight.w600,
                          color: isCur
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${item.origin} → ${item.destination} (${item.shipmentStatus})',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                      trailing: isCur
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary)
                          : const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textMuted),
                      onTap: () {
                        final mqtt = context.read<MqttProvider>();
                        final telemetry = context.read<TelemetryProvider>();
                        shipmentProvider.setActiveShipment(
                          item.id,
                          mqttProvider: mqtt,
                          telemetryProvider: telemetry,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Tracking switched to ${item.id} (${item.product})'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': ',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
