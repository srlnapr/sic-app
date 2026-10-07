// ============================================================
// main.dart - App entry point
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/alert.dart';
import 'providers/mqtt_provider.dart';
import 'providers/shipment_provider.dart';
import 'providers/telemetry_provider.dart';
import 'screens/alerts/alerts_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/monitoring/monitoring_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/shipments/shipments_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const FishGuardApp());
}

class FishGuardApp extends StatelessWidget {
  const FishGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TelemetryProvider()),
        ChangeNotifierProvider(create: (_) => ShipmentProvider()),
        ChangeNotifierProxyProvider<TelemetryProvider, MqttProvider>(
          create: (ctx) => MqttProvider(
            Provider.of<TelemetryProvider>(ctx, listen: false),
          ),
          update: (ctx, telemetry, previous) => previous ?? MqttProvider(telemetry),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;
  bool _initialized = false;

  final List<Widget> _screens = const [
    HomeScreen(),
    ShipmentsScreen(),
    MonitoringScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    final telemetry = context.read<TelemetryProvider>();
    final mqtt = context.read<MqttProvider>();
    final shipments = context.read<ShipmentProvider>();

    // Listen for alerts to show snackbars
    telemetry.addListener(() => _checkForNewAlerts(telemetry));

    // Keep active shipment condition status in sync with telemetry
    telemetry.addListener(() {
      shipments.updateActiveConditionStatus(telemetry.currentStatus);
    });

    // If demo mode is already on (from saved prefs), start demo
    final prefs = await SharedPreferences.getInstance();
    final isDemo =
        prefs.getBool(AppConstants.prefDemoMode) ?? telemetry.isDemoMode;

    if (isDemo) {
      await telemetry.setDemoMode(true);
    } else {
      // Try to connect to MQTT
      await mqtt.connect();
    }
  }

  String? _lastAlertId;

  void _checkForNewAlerts(TelemetryProvider telemetry) {
    if (telemetry.alerts.isEmpty) return;
    final latest = telemetry.alerts.first;
    if (latest.id == _lastAlertId) return;
    if (latest.isResolved) return;

    _lastAlertId = latest.id;

    final color = latest.severity == AlertSeverity.critical
        ? AppColors.statusCritical
        : AppColors.statusWarning;

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                latest.severity == AlertSeverity.critical
                    ? Icons.error_rounded
                    : Icons.warning_amber_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${latest.severityLabel}: ${latest.temperature.toStringAsFixed(1)}°C — ${latest.message}',
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () => setState(() => _currentIndex = 3),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<TelemetryProvider>(
      builder: (context, telemetry, _) {
        final unresolved =
            telemetry.alerts.where((a) => !a.isResolved).length;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.inventory_2_outlined,
                    activeIcon: Icons.inventory_2_rounded,
                    label: 'Shipments',
                    index: 1,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.show_chart_rounded,
                    activeIcon: Icons.show_chart_rounded,
                    label: 'Monitoring',
                    index: 2,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.notifications_outlined,
                    activeIcon: Icons.notifications_rounded,
                    label: 'Alerts',
                    index: 3,
                    currentIndex: currentIndex,
                    onTap: onTap,
                    badge: unresolved > 0 ? '$unresolved' : null,
                  ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'Settings',
                    index: 4,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    final color = isActive ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primarySurface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: color,
                    size: 22,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.statusCritical,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
