// ============================================================
// mqtt_status_indicator.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mqtt_provider.dart';
import '../providers/telemetry_provider.dart';
import '../services/mqtt_service.dart';
import '../utils/app_theme.dart';

class MqttStatusIndicator extends StatelessWidget {
  final bool showLabel;
  final bool compact;

  const MqttStatusIndicator({
    super.key,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<MqttProvider, TelemetryProvider>(
      builder: (context, mqtt, telemetry, _) {
        if (telemetry.isDemoMode) {
          return _buildChip(
            color: const Color(0xFF7C3AED),
            icon: Icons.science_outlined,
            label: 'DEMO MODE',
          );
        }

        switch (mqtt.connectionStatus) {
          case MqttConnectionStatus.connected:
            return _buildChip(
              color: AppColors.statusNormal,
              icon: Icons.wifi,
              label: showLabel ? 'MQTT Connected' : 'Connected',
            );
          case MqttConnectionStatus.connecting:
            return _buildChip(
              color: AppColors.statusWarning,
              icon: Icons.wifi_find,
              label: showLabel ? 'Connecting...' : 'Connecting',
              animate: true,
            );
          case MqttConnectionStatus.reconnecting:
            return _buildChip(
              color: AppColors.statusWarning,
              icon: Icons.sync,
              label: showLabel ? 'Reconnecting...' : 'Reconnecting',
              animate: true,
            );
          case MqttConnectionStatus.disconnected:
            return _buildChip(
              color: AppColors.statusCritical,
              icon: Icons.wifi_off,
              label: showLabel ? 'MQTT Disconnected' : 'Offline',
            );
          case MqttConnectionStatus.error:
            return _buildChip(
              color: const Color(0xFFEA580C),
              icon: Icons.warning_amber_outlined,
              label: showLabel ? 'MQTT Error' : 'Error',
            );
        }
      },
    );
  }

  Widget _buildChip({
    required Color color,
    required IconData icon,
    required String label,
    bool animate = false,
  }) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (animate)
            _PulsingDot(color: color)
          else
            Container(
              width: compact ? 7 : 8,
              height: compact ? 7 : 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
