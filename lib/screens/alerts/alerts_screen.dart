// ============================================================
// alerts_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/alert.dart';
import '../../providers/telemetry_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/alert_card.dart';

enum AlertFilter { all, active, critical, warning, resolved }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertFilter _selectedFilter = AlertFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          Consumer<TelemetryProvider>(
            builder: (context, telemetry, _) {
              if (telemetry.alerts.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _confirmClear(context, telemetry),
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TelemetryProvider>(
        builder: (context, telemetry, _) {
          final alerts = telemetry.alerts;

          final filteredAlerts = alerts.where((a) {
            switch (_selectedFilter) {
              case AlertFilter.all:
                return true;
              case AlertFilter.active:
                return !a.isResolved;
              case AlertFilter.critical:
                return a.severity == AlertSeverity.critical;
              case AlertFilter.warning:
                return a.severity == AlertSeverity.warning;
              case AlertFilter.resolved:
                return a.isResolved;
            }
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Row(
                  children: [
                    _AlertSummaryItem(
                      label: 'Total',
                      value: '${telemetry.totalAlerts}',
                      color: AppColors.primary,
                    ),
                    _VertDivider(),
                    _AlertSummaryItem(
                      label: 'Critical',
                      value: '${telemetry.criticalAlerts}',
                      color: AppColors.statusCritical,
                    ),
                    _VertDivider(),
                    _AlertSummaryItem(
                      label: 'Warning',
                      value: '${telemetry.warningAlerts}',
                      color: AppColors.statusWarning,
                    ),
                    _VertDivider(),
                    _AlertSummaryItem(
                      label: 'Resolved',
                      value: '${telemetry.resolvedAlerts}',
                      color: AppColors.statusNormal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(
                      label: 'All (${telemetry.totalAlerts})',
                      filter: AlertFilter.all,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Active (${telemetry.totalAlerts - telemetry.resolvedAlerts})',
                      filter: AlertFilter.active,
                      activeColor: AppColors.statusCritical,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Critical (${telemetry.criticalAlerts})',
                      filter: AlertFilter.critical,
                      activeColor: AppColors.statusCritical,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Warning (${telemetry.warningAlerts})',
                      filter: AlertFilter.warning,
                      activeColor: AppColors.statusWarning,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Resolved (${telemetry.resolvedAlerts})',
                      filter: AlertFilter.resolved,
                      activeColor: AppColors.statusNormal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (alerts.isEmpty)
                _EmptyAlerts()
              else if (filteredAlerts.isEmpty)
                _EmptyFilterAlerts(filterName: _filterLabel(_selectedFilter))
              else ...[
                _SectionHeader(
                  title: '${_filterLabel(_selectedFilter)} Alerts',
                  count: filteredAlerts.length,
                ),
                const SizedBox(height: 8),
                ...filteredAlerts.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AlertCard(
                      alert: a,
                      onResolve: a.isResolved
                          ? null
                          : () => telemetry.resolveAlert(a.id),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required AlertFilter filter,
    Color? activeColor,
  }) {
    final isSelected = _selectedFilter == filter;
    final color = activeColor ?? AppColors.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedFilter = filter);
      },
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      backgroundColor: AppColors.surface,
      selectedColor: color,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : AppColors.divider,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  String _filterLabel(AlertFilter filter) {
    switch (filter) {
      case AlertFilter.all:
        return 'All';
      case AlertFilter.active:
        return 'Active';
      case AlertFilter.critical:
        return 'Critical';
      case AlertFilter.warning:
        return 'Warning';
      case AlertFilter.resolved:
        return 'Resolved';
    }
  }

  void _confirmClear(BuildContext context, TelemetryProvider telemetry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Alerts'),
        content: const Text(
            'Are you sure you want to clear all alert history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              telemetry.clearAlerts();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusCritical),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _AlertSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AlertSummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: AppColors.divider);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.statusNormalBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 44,
              color: AppColors.statusNormal,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Alerts',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'All shipment conditions are within\nthe configured normal range.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilterAlerts extends StatelessWidget {
  final String filterName;
  const _EmptyFilterAlerts({required this.filterName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(Icons.filter_list_off_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No $filterName Alerts',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'There are no alerts matching this filter category.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
