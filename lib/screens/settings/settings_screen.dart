// ============================================================
// settings_screen.dart - Settings, Device Info, Demo Mode
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/mqtt_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../services/mqtt_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/thresholds.dart';
import '../../widgets/mqtt_status_indicator.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Demo Mode toggle
          _DemoModeCard(),
          const SizedBox(height: 12),

          // MQTT Configuration
          _MqttConfigCard(),
          const SizedBox(height: 12),

          // Device Information
          _DeviceInfoCard(),
          const SizedBox(height: 12),

          // Demo Control (visible when demo mode active)
          Consumer<TelemetryProvider>(
            builder: (context, telemetry, _) {
              if (!telemetry.isDemoMode) return const SizedBox.shrink();
              return Column(
                children: [
                  _DemoControlCard(),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),

          // App Info
          _AppInfoCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── Demo Mode Card ────────────────────────────────────────
class _DemoModeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<TelemetryProvider, MqttProvider>(
      builder: (context, telemetry, mqtt, _) {
        return Container(
          decoration: AppTheme.cardDecoration(
            borderColor: telemetry.isDemoMode
                ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                : AppColors.divider,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.science_outlined,
                          color: Color(0xFF7C3AED), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Demo Mode',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            telemetry.isDemoMode
                                ? 'Simulated telemetry every ${AppConstants.demoIntervalSeconds}s'
                                : 'Use simulated data without HiveMQ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: telemetry.isDemoMode,
                      onChanged: (v) async {
                        await telemetry.setDemoMode(v);
                        if (!v) {
                          await mqtt.connect();
                        } else {
                          await mqtt.disconnect();
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (telemetry.isDemoMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Demo mode generates simulated sensor data. Disable to use real MQTT.',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF7C3AED)),
                        ),
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
}

// ─── MQTT Configuration ───────────────────────────────────
class _MqttConfigCard extends StatefulWidget {
  @override
  State<_MqttConfigCard> createState() => _MqttConfigCardState();
}

class _MqttConfigCardState extends State<_MqttConfigCard> {
  bool _expanded = false;
  late TextEditingController _hostCtrl;
  late TextEditingController _portCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _passCtrl;
  late TextEditingController _topicCtrl;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _hostCtrl = TextEditingController();
    _portCtrl = TextEditingController();
    _userCtrl = TextEditingController();
    _passCtrl = TextEditingController();
    _topicCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(MqttProvider mqtt) {
    if (_hostCtrl.text.isEmpty) {
      _hostCtrl.text = mqtt.host;
      _portCtrl.text = '${mqtt.port}';
      _userCtrl.text = mqtt.username;
      _passCtrl.text = mqtt.password;
      _topicCtrl.text = mqtt.topic;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MqttProvider>(
      builder: (context, mqtt, _) {
        _syncControllers(mqtt);
        return Container(
          decoration: AppTheme.cardDecoration(),
          child: Column(
            children: [
              // Header
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_outlined,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MQTT Configuration',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${mqtt.host} • Port ${mqtt.port}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const MqttStatusIndicator(showLabel: false, compact: true),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preset buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _hostCtrl.text = 'broker.hivemq.com';
                                  _portCtrl.text = '8000';
                                  _userCtrl.text = '';
                                  _passCtrl.text = '';
                                  _topicCtrl.text = 'fishguard/fsh001/sensor';
                                });
                              },
                              icon: const Icon(Icons.flash_on_rounded, size: 14),
                              label: const Text('Preset Wokwi',
                                  style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _hostCtrl.text = 'broker.hivemq.com';
                                  _portCtrl.text = '8000';
                                  _userCtrl.text = '';
                                  _passCtrl.text = '';
                                  _topicCtrl.text = 'fishlogistics/FSH001/telemetry';
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: const Text('Reset Default',
                                  style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 16, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text(
                                  'Petunjuk Koneksi Wokwi:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '• Web App: broker.hivemq.com port 8000 (WebSocket)\n'
                              '• Wokwi ESP32: broker.hivemq.com port 1883 (TCP)\n'
                              '• Topic: fishguard/fsh001/sensor',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (mqtt.lastError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                AppColors.statusCritical.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.statusCritical
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.statusCritical, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  mqtt.lastError!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.statusCritical,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _buildField('Host', _hostCtrl,
                          hint: 'broker.hivemq.com'),
                      const SizedBox(height: 12),
                      _buildField('Port (WebSocket)', _portCtrl,
                          hint: '8000',
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildField('Username', _userCtrl),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildField('Topic', _topicCtrl,
                          hint: 'fishlogistics/FSH001/telemetry'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => mqtt.reconnect(),
                              icon: const Icon(Icons.refresh_rounded,
                                  size: 16),
                              label: const Text('Reconnect'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                    color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                final port =
                                    int.tryParse(_portCtrl.text) ??
                                        AppConstants.mqttPort;
                                await mqtt.saveConfig(
                                  host: _hostCtrl.text,
                                  port: port,
                                  username: _userCtrl.text,
                                  password: _passCtrl.text,
                                  topic: _topicCtrl.text,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Configuration saved'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.save_outlined, size: 16),
                              label: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}

// ─── Device Info Card ─────────────────────────────────────
class _DeviceInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<MqttProvider, TelemetryProvider>(
      builder: (context, mqtt, telemetry, _) {
        final lastUpdated = telemetry.latest?.timestamp;
        final isOnline = mqtt.connectionStatus == MqttConnectionStatus.connected
            || telemetry.isDemoMode;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.memory_rounded,
                        color: AppColors.textSecondary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Device Information',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        AppConstants.defaultDeviceId,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              _DeviceRow('Device ID', AppConstants.defaultDeviceId),
              _DeviceRow('Sensor', AppConstants.defaultSensor),
              _DeviceRow('Communication', 'MQTT over WebSocket (WSS)'),
              _DeviceRow('Broker', 'HiveMQ Cloud'),
              _DeviceRow('Topic', mqtt.topic),
              _DeviceRow(
                'Device Status',
                isOnline ? 'ONLINE' : 'OFFLINE',
                valueColor:
                    isOnline ? AppColors.statusNormal : AppColors.statusCritical,
              ),
              _DeviceRow(
                'Last Received',
                lastUpdated != null
                    ? DateFormat('HH:mm:ss dd MMM').format(lastUpdated)
                    : 'Never',
              ),
              _DeviceRow(
                'MQTT Connection',
                telemetry.isDemoMode ? 'DEMO MODE' : mqtt.statusLabel,
                valueColor: telemetry.isDemoMode
                    ? const Color(0xFF7C3AED)
                    : mqtt.connectionStatus == MqttConnectionStatus.connected
                        ? AppColors.statusNormal
                        : AppColors.statusCritical,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeviceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DeviceRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Demo Control Card ────────────────────────────────────
class _DemoControlCard extends StatefulWidget {
  @override
  State<_DemoControlCard> createState() => _DemoControlCardState();
}

class _DemoControlCardState extends State<_DemoControlCard> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TelemetryProvider>(
      builder: (context, telemetry, _) {
        final temp = telemetry.demoTemperature;
        final humid = telemetry.demoHumidity;
        final status = FishThresholds.computeStatus(temp);
        final statusColor = AppColors.statusColor(status);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(
            borderColor: const Color(0xFF7C3AED).withValues(alpha: 0.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded,
                      color: Color(0xFF7C3AED), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'DEMO CONTROL',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7C3AED),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Temperature slider
              Row(
                children: [
                  const Icon(Icons.device_thermostat,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text(
                    'Temperature',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    '${temp.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              Slider(
                value: temp,
                min: -5,
                max: 15,
                divisions: 200,
                onChanged: (v) {
                  telemetry.demoTemperature =
                      double.parse(v.toStringAsFixed(1));
                },
                onChangeEnd: (v) => telemetry.saveDemoSettings(),
              ),

              const SizedBox(height: 8),

              // Humidity slider
              Row(
                children: [
                  const Icon(Icons.water_drop_outlined,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text(
                    'Humidity',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    '${humid.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              Slider(
                value: humid,
                min: 0,
                max: 100,
                divisions: 100,
                activeColor: AppColors.accent,
                onChanged: (v) {
                  telemetry.demoHumidity =
                      double.parse(v.toStringAsFixed(0));
                },
                onChangeEnd: (v) => telemetry.saveDemoSettings(),
              ),

              const SizedBox(height: 12),

              // Status preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusBgColor(status),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.statusBorderColor(status)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusIcon(status),
                      color: statusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${temp.toStringAsFixed(1)}°C → Status: $status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Send test data button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    telemetry.sendDemoData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Sent: ${temp.toStringAsFixed(1)}°C — $status'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: statusColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('SEND TEST DATA'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case FishThresholds.statusNormal:
        return Icons.check_circle_rounded;
      case FishThresholds.statusWarning:
        return Icons.warning_amber_rounded;
      case FishThresholds.statusCritical:
        return Icons.error_rounded;
      default:
        return Icons.help_outline;
    }
  }
}

// ─── App Info Card ────────────────────────────────────────
class _AppInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.set_meal_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FishGuard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Version ${AppConstants.appVersion}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Text(
            'Smart Monitoring for Safer Fish Logistics\n'
            'Built for Samsung Innovation Campus\n'
            'IoT Project with ESP32 + DHT22 + HiveMQ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
