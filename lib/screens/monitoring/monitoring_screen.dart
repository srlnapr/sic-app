// ============================================================
// monitoring_screen.dart - Real-time temperature monitoring
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/telemetry_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/thresholds.dart';
import '../../widgets/temperature_chart.dart';

class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Temperature Monitoring'),
      ),
      body: Consumer<TelemetryProvider>(
        builder: (context, telemetry, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats row
              Row(
                children: [
                  _StatBox(
                    label: 'Current',
                    value: telemetry.history.isEmpty
                        ? '--'
                        : '${telemetry.currentTemperature.toStringAsFixed(1)}°C',
                    color: AppColors.statusColor(telemetry.currentStatus),
                  ),
                  const SizedBox(width: 8),
                  _StatBox(
                    label: 'Minimum',
                    value: telemetry.history.isEmpty
                        ? '--'
                        : '${telemetry.minTemperature.toStringAsFixed(1)}°C',
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  _StatBox(
                    label: 'Maximum',
                    value: telemetry.history.isEmpty
                        ? '--'
                        : '${telemetry.maxTemperature.toStringAsFixed(1)}°C',
                    color: AppColors.statusCritical,
                  ),
                  const SizedBox(width: 8),
                  _StatBox(
                    label: 'Average',
                    value: telemetry.history.isEmpty
                        ? '--'
                        : '${telemetry.avgTemperature.toStringAsFixed(1)}°C',
                    color: AppColors.statusWarning,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Chart
              Container(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Text(
                            'Temperature History',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${telemetry.history.length} readings',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const TemperatureChart(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Threshold legend
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONFIGURED THRESHOLDS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Demo thresholds for this project — not universal scientific limits.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ThresholdRow(
                      color: AppColors.statusNormal,
                      label: 'Normal',
                      description: FishThresholds.normalRange,
                      detail: FishThresholds.normalDetail,
                    ),
                    const SizedBox(height: 10),
                    _ThresholdRow(
                      color: AppColors.statusWarning,
                      label: 'Warning',
                      description: FishThresholds.warningRange,
                      detail: FishThresholds.warningDetail,
                    ),
                    const SizedBox(height: 10),
                    _ThresholdRow(
                      color: AppColors.statusCritical,
                      label: 'Critical',
                      description: FishThresholds.criticalRange,
                      detail: FishThresholds.criticalDetail,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recent readings
              if (telemetry.history.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECENT READINGS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...telemetry.history.reversed
                          .take(10)
                          .map((t) => _ReadingRow(data: t)),
                    ],
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
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: AppTheme.cardDecoration(),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
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

class _ThresholdRow extends StatelessWidget {
  final Color color;
  final String label;
  final String description;
  final String detail;
  const _ThresholdRow({
    required this.color,
    required this.label,
    required this.description,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$label  ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              detail,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReadingRow extends StatelessWidget {
  final dynamic data;
  const _ReadingRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(data.status as String);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '${(data.temperature as double).toStringAsFixed(1)}°C',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(data.humidity as double).toStringAsFixed(1)}% RH',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.statusBgColor(data.status as String),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.statusBorderColor(data.status as String),
                width: 0.8,
              ),
            ),
            child: Text(
              data.status as String,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const Spacer(),
          Text(
            _formatTime(data.timestamp as DateTime),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
