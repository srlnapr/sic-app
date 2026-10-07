// ============================================================
// temperature_chart.dart - Real-time fl_chart line chart
// ============================================================
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/telemetry_provider.dart';
import '../utils/app_theme.dart';
import '../utils/thresholds.dart';

class TemperatureChart extends StatelessWidget {
  const TemperatureChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TelemetryProvider>(
      builder: (context, telemetry, _) {
        final history = telemetry.history;

        if (history.isEmpty) {
          return Container(
            height: 220,
            decoration: AppTheme.cardDecoration(),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart_rounded,
                      size: 48, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text(
                    'Waiting for data...',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        final spots = <FlSpot>[];
        for (var i = 0; i < history.length; i++) {
          spots.add(FlSpot(i.toDouble(), history[i].temperature));
        }

        final showCount = history.length.clamp(2, 100);

        return Container(
          decoration: AppTheme.cardDecoration(),
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (showCount - 1).toDouble(),
                minY: FishThresholds.chartMinY,
                maxY: FishThresholds.chartMaxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: 4,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}°',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: (showCount / 4).ceilToDouble().clamp(1, 999),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= history.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          DateFormat('HH:mm').format(history[idx].timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    // Normal threshold line
                    HorizontalLine(
                      y: FishThresholds.normalMax,
                      color: AppColors.statusNormal.withValues(alpha: 0.7),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppColors.statusNormal,
                          fontWeight: FontWeight.w600,
                        ),
                        labelResolver: (_) =>
                            'Normal ≤${FishThresholds.normalMax.toInt()}°C',
                      ),
                    ),
                    // Warning threshold line
                    HorizontalLine(
                      y: FishThresholds.warningMax,
                      color: AppColors.statusWarning.withValues(alpha: 0.7),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppColors.statusWarning,
                          fontWeight: FontWeight.w600,
                        ),
                        labelResolver: (_) =>
                            'Warning ≤${FishThresholds.warningMax.toInt()}°C',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.chartLine,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 20,
                      getDotPainter: (spot, _, __, ___) {
                        final temp = spot.y;
                        final statusColor = temp <= FishThresholds.normalMax
                            ? AppColors.statusNormal
                            : temp <= FishThresholds.warningMax
                                ? AppColors.statusWarning
                                : AppColors.statusCritical;
                        return FlDotCirclePainter(
                          radius: 3,
                          color: statusColor,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.chartLine.withValues(alpha: 0.2),
                          AppColors.chartLine.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primary,
                    getTooltipItems: (spots) => spots.map((s) {
                      final idx = s.x.toInt();
                      final ts = idx < history.length
                          ? history[idx].timestamp
                          : DateTime.now();
                      return LineTooltipItem(
                        '${s.y.toStringAsFixed(1)}°C\n',
                        GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: DateFormat('HH:mm:ss').format(ts),
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 250),
            ),
          ),
        );
      },
    );
  }
}
