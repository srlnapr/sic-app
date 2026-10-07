// ============================================================
// shipment_provider.dart - State management for shipments
// ============================================================
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shipment.dart';
import 'mqtt_provider.dart';
import 'telemetry_provider.dart';

const String _prefShipmentsKey = 'custom_shipments_list';
const String _prefActiveShipmentKey = 'active_shipment_id';

class ShipmentProvider extends ChangeNotifier {
  final List<Shipment> _shipments = [];
  String _activeShipmentId = 'FSH001';

  String _searchQuery = '';
  String _statusFilter = 'ALL';

  List<Shipment> get allShipments => List.unmodifiable(_shipments);
  String get activeShipmentId => _activeShipmentId;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  Shipment? get activeShipment {
    final idx = _shipments.indexWhere((s) => s.id == _activeShipmentId);
    if (idx != -1) return _shipments[idx];
    final active = _shipments.where((s) => s.isActive).toList();
    if (active.isNotEmpty) return active.first;
    return _shipments.isNotEmpty ? _shipments.first : null;
  }

  // Stats
  int get totalCount => _shipments.length;
  int get inTransitCount =>
      _shipments.where((s) => s.shipmentStatus == ShipmentStatus.inTransit).length;
  int get completedCount =>
      _shipments.where((s) => s.shipmentStatus == ShipmentStatus.completed).length;
  int get scheduledCount =>
      _shipments.where((s) => s.shipmentStatus == ShipmentStatus.scheduled).length;
  int get delayedCount =>
      _shipments.where((s) => s.shipmentStatus == ShipmentStatus.delayed).length;

  /// Filtered list by search text and status category
  List<Shipment> get filteredShipments {
    return _shipments.where((s) {
      // Filter by status
      if (_statusFilter != 'ALL' && s.shipmentStatus != _statusFilter) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesId = s.id.toLowerCase().contains(q);
        final matchesProduct = s.product.toLowerCase().contains(q);
        final matchesOrigin = s.origin.toLowerCase().contains(q);
        final matchesDestination = s.destination.toLowerCase().contains(q);
        final matchesDevice = s.deviceId.toLowerCase().contains(q);
        return matchesId ||
            matchesProduct ||
            matchesOrigin ||
            matchesDestination ||
            matchesDevice;
      }

      return true;
    }).toList();
  }

  ShipmentProvider() {
    _loadShipments();
  }

  Future<void> _loadShipments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefActiveShipmentKey);
      if (savedId != null && savedId.isNotEmpty) {
        _activeShipmentId = savedId;
      }

      final jsonStr = prefs.getString(_prefShipmentsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final loaded = Shipment.decodeList(jsonStr);
        if (loaded.isNotEmpty) {
          _shipments.clear();
          _shipments.addAll(loaded);
          _ensureActiveSync();
          notifyListeners();
          return;
        }
      }

      // Default seed shipments
      _shipments.clear();
      _shipments.addAll(Shipment.defaultShipments);
      _ensureActiveSync();
      _saveShipments();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load shipments: $e');
    }
  }

  Future<void> _saveShipments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefShipmentsKey, Shipment.encodeList(_shipments));
      await prefs.setString(_prefActiveShipmentKey, _activeShipmentId);
    } catch (e) {
      debugPrint('Failed to persist shipments: $e');
    }
  }

  void _ensureActiveSync() {
    for (int i = 0; i < _shipments.length; i++) {
      final isIt = _shipments[i].id == _activeShipmentId;
      if (_shipments[i].isActive != isIt) {
        _shipments[i] = _shipments[i].copyWith(isActive: isIt);
      }
    }
  }

  void setSearchQuery(String q) {
    _searchQuery = q.trim();
    notifyListeners();
  }

  void setStatusFilter(String s) {
    _statusFilter = s;
    notifyListeners();
  }

  /// Set the active monitored shipment and update MQTT topic if providers passed
  Future<void> setActiveShipment(
    String shipmentId, {
    MqttProvider? mqttProvider,
    TelemetryProvider? telemetryProvider,
  }) async {
    final idx = _shipments.indexWhere((s) => s.id == shipmentId);
    if (idx == -1) return;

    _activeShipmentId = shipmentId;
    _ensureActiveSync();
    await _saveShipments();
    notifyListeners();

    // Auto-switch MQTT topic to: fishlogistics/{shipmentId}/telemetry
    final newTopic = 'fishlogistics/$shipmentId/telemetry';
    if (mqttProvider != null) {
      await mqttProvider.switchTopic(newTopic);
    }
  }

  /// Add a brand new shipment
  Future<void> addShipment(Shipment newShipment, {bool setAsActive = false}) async {
    _shipments.insert(0, newShipment);
    if (setAsActive || _shipments.length == 1) {
      _activeShipmentId = newShipment.id;
      _ensureActiveSync();
    }
    await _saveShipments();
    notifyListeners();
  }

  /// Update an existing shipment
  Future<void> updateShipment(Shipment updated) async {
    final idx = _shipments.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      _shipments[idx] = updated;
      _ensureActiveSync();
      await _saveShipments();
      notifyListeners();
    }
  }

  /// Delete a shipment
  Future<void> deleteShipment(String id) async {
    final idx = _shipments.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _shipments.removeAt(idx);
      if (_activeShipmentId == id && _shipments.isNotEmpty) {
        _activeShipmentId = _shipments.first.id;
        _ensureActiveSync();
      }
      await _saveShipments();
      notifyListeners();
    }
  }

  /// Update the logistics status (IN TRANSIT, COMPLETED, DELAYED, SCHEDULED)
  Future<void> updateShipmentStatus(String shipmentId, String newStatus) async {
    final idx = _shipments.indexWhere((s) => s.id == shipmentId);
    if (idx != -1) {
      _shipments[idx] = _shipments[idx].copyWith(shipmentStatus: newStatus);
      await _saveShipments();
      notifyListeners();
    }
  }

  /// Update the IoT condition status (NORMAL, WARNING, CRITICAL)
  void updateActiveConditionStatus(String status) {
    final idx = _shipments.indexWhere((s) => s.id == _activeShipmentId);
    if (idx != -1 && _shipments[idx].conditionStatus != status) {
      _shipments[idx] = _shipments[idx].copyWith(conditionStatus: status);
      notifyListeners();
    }
  }
}
