// ============================================================
// shipments_screen.dart - Dynamic Shipment Management
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/shipment.dart';
import '../../providers/mqtt_provider.dart';
import '../../providers/shipment_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shipment_card.dart';

class ShipmentsScreen extends StatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  State<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shipments & Cargo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Shipment',
            onPressed: () => _openAddShipmentModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddShipmentModal(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Shipment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      body: Consumer2<ShipmentProvider, TelemetryProvider>(
        builder: (context, shipmentProvider, telemetry, _) {
          final shipments = shipmentProvider.filteredShipments;
          final active = shipmentProvider.activeShipment;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Search Input
              Container(
                decoration: AppTheme.cardDecoration(),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => shipmentProvider.setSearchQuery(v),
                  decoration: InputDecoration(
                    hintText: 'Search shipment ID, fish, route, driver...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _searchCtrl.clear();
                              shipmentProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Summary Counters Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Row(
                  children: [
                    _SummaryItem(
                      label: 'Total',
                      value: '${shipmentProvider.totalCount}',
                      color: AppColors.primary,
                    ),
                    _Divider(),
                    _SummaryItem(
                      label: 'In Transit',
                      value: '${shipmentProvider.inTransitCount}',
                      color: AppColors.accent,
                    ),
                    _Divider(),
                    _SummaryItem(
                      label: 'Scheduled',
                      value: '${shipmentProvider.scheduledCount}',
                      color: const Color(0xFF7C3AED),
                    ),
                    _Divider(),
                    _SummaryItem(
                      label: 'Completed',
                      value: '${shipmentProvider.completedCount}',
                      color: AppColors.statusNormal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(
                      label: 'All (${shipmentProvider.totalCount})',
                      status: 'ALL',
                      provider: shipmentProvider,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'In Transit (${shipmentProvider.inTransitCount})',
                      status: ShipmentStatus.inTransit,
                      provider: shipmentProvider,
                      activeColor: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Scheduled (${shipmentProvider.scheduledCount})',
                      status: ShipmentStatus.scheduled,
                      provider: shipmentProvider,
                      activeColor: const Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Completed (${shipmentProvider.completedCount})',
                      status: ShipmentStatus.completed,
                      provider: shipmentProvider,
                      activeColor: AppColors.statusNormal,
                    ),
                    if (shipmentProvider.delayedCount > 0) ...[
                      const SizedBox(width: 8),
                      _filterChip(
                        label: 'Delayed (${shipmentProvider.delayedCount})',
                        status: ShipmentStatus.delayed,
                        provider: shipmentProvider,
                        activeColor: AppColors.statusCritical,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (shipments.isEmpty)
                _EmptyShipments(
                  searchQuery: shipmentProvider.searchQuery,
                  filter: shipmentProvider.statusFilter,
                  onReset: () {
                    _searchCtrl.clear();
                    shipmentProvider.setSearchQuery('');
                    shipmentProvider.setStatusFilter('ALL');
                  },
                )
              else ...[
                // Active shipment section (if matches filter)
                if (active != null && shipments.any((s) => s.id == active.id)) ...[
                  _SectionHeader(title: 'Actively Monitored Cargo', count: 1),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ShipmentCard(
                      shipment: active,
                      temperature: telemetry.currentTemperature,
                      humidity: telemetry.currentHumidity,
                      onTap: () => _openDetail(context, active),
                    ),
                  ),
                ],

                // Other Shipments section
                if (shipments.any((s) => s.id != active?.id)) ...[
                  _SectionHeader(
                    title: 'All Shipments',
                    count: shipments.where((s) => s.id != active?.id).length,
                  ),
                  const SizedBox(height: 8),
                  ...shipments.where((s) => s.id != active?.id).map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ShipmentCard(
                            shipment: s,
                            onTap: () => _openDetail(context, s),
                            onSetActive: () => _switchActiveCargo(context, s.id),
                          ),
                        ),
                      ),
                ],
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
    required String status,
    required ShipmentProvider provider,
    Color? activeColor,
  }) {
    final isSelected = provider.statusFilter == status;
    final color = activeColor ?? AppColors.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setStatusFilter(status),
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

  void _switchActiveCargo(BuildContext context, String shipmentId) {
    final shipmentProvider = context.read<ShipmentProvider>();
    final mqttProvider = context.read<MqttProvider>();
    final telemetry = context.read<TelemetryProvider>();

    shipmentProvider.setActiveShipment(
      shipmentId,
      mqttProvider: mqttProvider,
      telemetryProvider: telemetry,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Active tracking switched to $shipmentId (Topic: fishlogistics/$shipmentId/telemetry)',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openDetail(BuildContext context, Shipment shipment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShipmentDetailScreen(shipmentId: shipment.id),
      ),
    );
  }

  void _openAddShipmentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddShipmentSheet(),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
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
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.divider,
    );
  }
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

class _EmptyShipments extends StatelessWidget {
  final String searchQuery;
  final String filter;
  final VoidCallback onReset;

  const _EmptyShipments({
    required this.searchQuery,
    required this.filter,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 36, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty
                ? 'No shipments match "$searchQuery"'
                : 'No shipments in category "$filter"',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search query or status filter.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset Filters'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modal Sheet: Add Shipment ──────────────────────────────

class _AddShipmentSheet extends StatefulWidget {
  const _AddShipmentSheet();

  @override
  State<_AddShipmentSheet> createState() => _AddShipmentSheetState();
}

class _AddShipmentSheetState extends State<_AddShipmentSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _idCtrl;
  late TextEditingController _productCtrl;
  late TextEditingController _originCtrl;
  late TextEditingController _destinationCtrl;
  late TextEditingController _driverCtrl;
  late TextEditingController _plateCtrl;
  late TextEditingController _deviceCtrl;
  late TextEditingController _notesCtrl;

  String _status = ShipmentStatus.inTransit;
  double _targetTempMin = 0.0;
  double _targetTempMax = 4.0;
  bool _setAsActive = true;

  @override
  void initState() {
    super.initState();
    final count = context.read<ShipmentProvider>().allShipments.length + 1;
    final generatedId = 'FSH${count.toString().padLeft(3, '0')}';

    _idCtrl = TextEditingController(text: generatedId);
    _productCtrl = TextEditingController(text: 'Fresh Tuna Loin');
    _originCtrl = TextEditingController(text: 'Cilacap');
    _destinationCtrl = TextEditingController(text: 'Jakarta');
    _driverCtrl = TextEditingController(text: 'Samsul Arifin');
    _plateCtrl = TextEditingController(text: 'B 3021 PZX');
    _deviceCtrl = TextEditingController(text: 'ESP32-$generatedId');
    _notesCtrl = TextEditingController(text: 'Box thermoking cold storage');
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _productCtrl.dispose();
    _originCtrl.dispose();
    _destinationCtrl.dispose();
    _driverCtrl.dispose();
    _plateCtrl.dispose();
    _deviceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header bar
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
                  const Icon(Icons.add_box_rounded,
                      color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Add New Shipment',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Register a new seafood cargo container for IoT cold-chain tracking.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),

              // ID & Device ID Row
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      label: 'Shipment ID',
                      controller: _idCtrl,
                      hint: 'FSH005',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInput(
                      label: 'Device ID',
                      controller: _deviceCtrl,
                      hint: 'ESP32-FSH005',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Product
              _buildInput(
                label: 'Seafood Product',
                controller: _productCtrl,
                hint: 'e.g. Fresh Tuna Fillet, Vannamei Shrimp',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Route Origin & Destination
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      label: 'Origin (Asal)',
                      controller: _originCtrl,
                      hint: 'e.g. Cilacap, Bali',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInput(
                      label: 'Destination (Tujuan)',
                      controller: _destinationCtrl,
                      hint: 'e.g. Jakarta, Bandung',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Driver & Vehicle Plate
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      label: 'Driver Name',
                      controller: _driverCtrl,
                      hint: 'Nama Driver',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInput(
                      label: 'Vehicle Plate',
                      controller: _plateCtrl,
                      hint: 'Plat Nomor',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Status Dropdown
              const Text(
                'Logistics Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _status,
                    isExpanded: true,
                    items: ShipmentStatus.allStatuses.map((s) {
                      return DropdownMenuItem<String>(
                        value: s,
                        child: Text(s,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Target Temp Range Preset
              const Text(
                'Cold-Chain Target Temperature (°C)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _presetChip('Fresh Fish (0-4°C)', 0.0, 4.0),
                  const SizedBox(width: 8),
                  _presetChip('Frozen (-18 to -5°C)', -18.0, -5.0),
                  const SizedBox(width: 8),
                  _presetChip('Live Seafood (12-18°C)', 12.0, 18.0),
                ],
              ),
              const SizedBox(height: 14),

              // Active switch toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Set as actively tracked cargo immediately',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Automatically switches the app and MQTT topic to this shipment',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                value: _setAsActive,
                onChanged: (v) => setState(() => _setAsActive = v),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('CREATE & SAVE SHIPMENT'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String label, double min, double max) {
    final isSelected = _targetTempMin == min && _targetTempMax == max;
    return GestureDetector(
      onTap: () {
        setState(() {
          _targetTempMin = min;
          _targetTempMax = max;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySurface
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final id = _idCtrl.text.trim().toUpperCase();
    final newShipment = Shipment(
      id: id,
      product: _productCtrl.text.trim(),
      origin: _originCtrl.text.trim(),
      destination: _destinationCtrl.text.trim(),
      shipmentStatus: _status,
      conditionStatus: 'NORMAL',
      deviceId: _deviceCtrl.text.trim(),
      isActive: _setAsActive,
      departureTime: DateTime.now(),
      estimatedArrival: DateTime.now().add(const Duration(hours: 8)),
      driverName: _driverCtrl.text.trim().isNotEmpty
          ? _driverCtrl.text.trim()
          : null,
      vehiclePlate: _plateCtrl.text.trim().isNotEmpty
          ? _plateCtrl.text.trim()
          : null,
      notes: _notesCtrl.text.trim().isNotEmpty
          ? _notesCtrl.text.trim()
          : null,
      targetTempMin: _targetTempMin,
      targetTempMax: _targetTempMax,
    );

    final shipmentProvider = context.read<ShipmentProvider>();
    final mqttProvider = context.read<MqttProvider>();
    final telemetry = context.read<TelemetryProvider>();

    shipmentProvider.addShipment(newShipment, setAsActive: _setAsActive);
    if (_setAsActive) {
      shipmentProvider.setActiveShipment(id,
          mqttProvider: mqttProvider, telemetryProvider: telemetry);
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shipment $id created successfully!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.statusNormal,
      ),
    );
  }
}

// ─── Shipment Detail Screen ──────────────────────────────────

class ShipmentDetailScreen extends StatelessWidget {
  final String shipmentId;

  const ShipmentDetailScreen({
    super.key,
    required this.shipmentId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<ShipmentProvider, TelemetryProvider>(
      builder: (context, shipmentProvider, telemetry, _) {
        final matches = shipmentProvider.allShipments
            .where((s) => s.id == shipmentId)
            .toList();

        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Shipment Details')),
            body: const Center(child: Text('Shipment not found')),
          );
        }

        final shipment = matches.first;
        final isActive = shipment.isActive;
        final status =
            isActive ? telemetry.currentStatus : shipment.conditionStatus;
        final temp = isActive ? telemetry.currentTemperature : null;
        final humid = isActive ? telemetry.currentHumidity : null;
        final lastUpdated = isActive ? telemetry.latest?.timestamp : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(shipment.id),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete Shipment',
                onPressed: () => _confirmDelete(context, shipmentProvider, shipment),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Active Banner / Selector
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.statusNormalBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.statusNormalBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sensors_rounded,
                          color: AppColors.statusNormal, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Actively Monitored — Streaming live telemetry via HiveMQ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusNormal,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Not currently monitored in live stream.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          final mqtt = context.read<MqttProvider>();
                          shipmentProvider.setActiveShipment(
                            shipment.id,
                            mqttProvider: mqtt,
                            telemetryProvider: telemetry,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Switched live monitoring to ${shipment.id}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Track Now',
                            style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),

              // Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(
                  borderColor: AppColors.statusBorderColor(status),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.statusBgColor(status),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _statusIcon(status),
                        color: AppColors.statusColor(status),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Condition Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.statusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ShipmentStatusBadge(status: shipment.shipmentStatus),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Route & Timeline Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('Logistics Route & Timeline'),
                    const SizedBox(height: 16),
                    _RouteStep(
                      title: 'Dispatched / Origin',
                      subtitle: shipment.origin,
                      time: shipment.departureTime != null
                          ? DateFormat('dd MMM yyyy HH:mm')
                              .format(shipment.departureTime!)
                          : null,
                      isDone: true,
                      isFirst: true,
                    ),
                    _RouteStep(
                      title: 'In Transit',
                      subtitle:
                          'Monitoring cold-chain: ${shipment.product}',
                      time: shipment.shipmentStatus == ShipmentStatus.inTransit
                          ? 'Active Transit'
                          : null,
                      isDone: shipment.shipmentStatus ==
                              ShipmentStatus.inTransit ||
                          shipment.shipmentStatus == ShipmentStatus.completed,
                      isActive: shipment.shipmentStatus ==
                          ShipmentStatus.inTransit,
                    ),
                    _RouteStep(
                      title: 'Arrival / Destination',
                      subtitle: shipment.destination,
                      time: shipment.estimatedArrival != null
                          ? 'Est: ${DateFormat('dd MMM yyyy HH:mm').format(shipment.estimatedArrival!)}'
                          : null,
                      isDone: shipment.shipmentStatus ==
                          ShipmentStatus.completed,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Live Sensor Readings (if active)
              if (isActive && temp != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle('Live Sensor Readings (DHT22)'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _SensorChip(
                            label: 'Temperature',
                            value: '${temp.toStringAsFixed(1)}°C',
                            icon: Icons.device_thermostat,
                            color: AppColors.statusColor(status),
                          ),
                          const SizedBox(width: 10),
                          _SensorChip(
                            label: 'Humidity',
                            value: '${humid!.toStringAsFixed(0)}% RH',
                            icon: Icons.water_drop_outlined,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                      if (lastUpdated != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              'Last received: ${DateFormat('HH:mm:ss dd MMM').format(lastUpdated)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Cargo & Hardware Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('Cargo Specifications'),
                    const SizedBox(height: 14),
                    _DetailRow('Product', shipment.product),
                    _DetailRow('Device ID', shipment.deviceId),
                    _DetailRow(
                      'Target Temp',
                      '${shipment.targetTempMin.toStringAsFixed(0)}°C to ${shipment.targetTempMax.toStringAsFixed(0)}°C',
                    ),
                    if (shipment.driverName != null)
                      _DetailRow('Driver', shipment.driverName!),
                    if (shipment.vehiclePlate != null)
                      _DetailRow('Vehicle Plate', shipment.vehiclePlate!),
                    if (shipment.notes != null)
                      _DetailRow('Notes', shipment.notes!),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Update Logistics Status Action
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('Update Logistics Status'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ShipmentStatus.allStatuses.map((st) {
                        final isCur = shipment.shipmentStatus == st;
                        return ChoiceChip(
                          label: Text(st),
                          selected: isCur,
                          onSelected: (selected) {
                            if (selected) {
                              shipmentProvider.updateShipmentStatus(
                                  shipment.id, st);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Status updated to $st'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isCur ? Colors.white : AppColors.textPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    ShipmentProvider provider,
    Shipment shipment,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${shipment.id}?'),
        content: Text(
          'Are you sure you want to remove ${shipment.product} (${shipment.id}) from the tracking database?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteShipment(shipment.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusCritical),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return Icons.check_circle_rounded;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'CRITICAL':
        return Icons.error_rounded;
      default:
        return Icons.help_outline;
    }
  }
}

class _RouteStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? time;
  final bool isDone;
  final bool isActive;
  final bool isFirst;
  final bool isLast;

  const _RouteStep({
    required this.title,
    required this.subtitle,
    this.time,
    this.isDone = false,
    this.isActive = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final circleColor = isDone
        ? AppColors.statusNormal
        : isActive
            ? AppColors.accent
            : AppColors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: circleColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: circleColor, width: 2),
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isDone
                    ? AppColors.statusNormal.withValues(alpha: 0.5)
                    : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDone || isActive
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  if (time != null)
                    Text(
                      time!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SensorChip({
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
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
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
