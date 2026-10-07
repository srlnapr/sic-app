// ============================================================
// shipment.dart - Shipment data model
// ============================================================
import 'dart:convert';

class ShipmentStatus {
  static const String scheduled = 'SCHEDULED';
  static const String inTransit = 'IN TRANSIT';
  static const String completed = 'COMPLETED';
  static const String delayed = 'DELAYED';

  static List<String> get allStatuses => [
        scheduled,
        inTransit,
        completed,
        delayed,
      ];
}

class Shipment {
  final String id;
  final String product;
  final String origin;
  final String destination;
  final String shipmentStatus; // SCHEDULED, IN TRANSIT, COMPLETED, DELAYED
  final String conditionStatus; // NORMAL, WARNING, CRITICAL
  final String deviceId;
  final bool isActive;
  final DateTime? departureTime;
  final DateTime? estimatedArrival;
  final String? driverName;
  final String? vehiclePlate;
  final String? notes;
  final double targetTempMin;
  final double targetTempMax;

  const Shipment({
    required this.id,
    required this.product,
    required this.origin,
    required this.destination,
    required this.shipmentStatus,
    required this.conditionStatus,
    required this.deviceId,
    this.isActive = false,
    this.departureTime,
    this.estimatedArrival,
    this.driverName,
    this.vehiclePlate,
    this.notes,
    this.targetTempMin = 0.0,
    this.targetTempMax = 4.0,
  });

  /// Approximate progress between departure and estimated arrival (0.0 to 1.0)
  double get progressRatio {
    if (shipmentStatus == ShipmentStatus.completed) return 1.0;
    if (shipmentStatus == ShipmentStatus.scheduled) return 0.0;
    if (departureTime == null || estimatedArrival == null) return 0.5;

    final now = DateTime.now();
    if (now.isBefore(departureTime!)) return 0.0;
    if (now.isAfter(estimatedArrival!)) return 0.95;

    final totalDuration =
        estimatedArrival!.difference(departureTime!).inSeconds;
    if (totalDuration <= 0) return 0.5;
    final elapsed = now.difference(departureTime!).inSeconds;
    return (elapsed / totalDuration).clamp(0.05, 0.95);
  }

  Shipment copyWith({
    String? id,
    String? product,
    String? origin,
    String? destination,
    String? conditionStatus,
    String? shipmentStatus,
    String? deviceId,
    bool? isActive,
    DateTime? departureTime,
    DateTime? estimatedArrival,
    String? driverName,
    String? vehiclePlate,
    String? notes,
    double? targetTempMin,
    double? targetTempMax,
  }) {
    return Shipment(
      id: id ?? this.id,
      product: product ?? this.product,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      shipmentStatus: shipmentStatus ?? this.shipmentStatus,
      conditionStatus: conditionStatus ?? this.conditionStatus,
      deviceId: deviceId ?? this.deviceId,
      isActive: isActive ?? this.isActive,
      departureTime: departureTime ?? this.departureTime,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      driverName: driverName ?? this.driverName,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      notes: notes ?? this.notes,
      targetTempMin: targetTempMin ?? this.targetTempMin,
      targetTempMax: targetTempMax ?? this.targetTempMax,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product': product,
        'origin': origin,
        'destination': destination,
        'shipmentStatus': shipmentStatus,
        'conditionStatus': conditionStatus,
        'deviceId': deviceId,
        'isActive': isActive,
        'departureTime': departureTime?.toIso8601String(),
        'estimatedArrival': estimatedArrival?.toIso8601String(),
        'driverName': driverName,
        'vehiclePlate': vehiclePlate,
        'notes': notes,
        'targetTempMin': targetTempMin,
        'targetTempMax': targetTempMax,
      };

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id'] as String? ?? 'UNKNOWN',
      product: json['product'] as String? ?? 'Fresh Fish',
      origin: json['origin'] as String? ?? 'Unknown',
      destination: json['destination'] as String? ?? 'Unknown',
      shipmentStatus:
          json['shipmentStatus'] as String? ?? ShipmentStatus.inTransit,
      conditionStatus: json['conditionStatus'] as String? ?? 'NORMAL',
      deviceId: json['deviceId'] as String? ?? 'ESP32-GEN',
      isActive: json['isActive'] as bool? ?? false,
      departureTime: json['departureTime'] != null
          ? DateTime.tryParse(json['departureTime'] as String)
          : null,
      estimatedArrival: json['estimatedArrival'] != null
          ? DateTime.tryParse(json['estimatedArrival'] as String)
          : null,
      driverName: json['driverName'] as String?,
      vehiclePlate: json['vehiclePlate'] as String?,
      notes: json['notes'] as String?,
      targetTempMin: (json['targetTempMin'] as num?)?.toDouble() ?? 0.0,
      targetTempMax: (json['targetTempMax'] as num?)?.toDouble() ?? 4.0,
    );
  }

  static String encodeList(List<Shipment> list) =>
      jsonEncode(list.map((s) => s.toJson()).toList());

  static List<Shipment> decodeList(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => Shipment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Default shipments for demo
  static List<Shipment> get defaultShipments => [
        Shipment(
          id: 'FSH001',
          product: 'Fresh Tuna Fillet',
          origin: 'Cilacap',
          destination: 'Jakarta',
          shipmentStatus: ShipmentStatus.inTransit,
          conditionStatus: 'NORMAL',
          deviceId: 'ESP32-FSH001',
          isActive: true,
          departureTime: DateTime.now().subtract(const Duration(hours: 3)),
          estimatedArrival: DateTime.now().add(const Duration(hours: 5)),
          driverName: 'Budi Santoso',
          vehiclePlate: 'B 9421 KDA',
          notes: 'Refrigerated truck box #02, optimal cold-chain storage',
          targetTempMin: 0.0,
          targetTempMax: 4.0,
        ),
        Shipment(
          id: 'FSH002',
          product: 'Fresh Salmon',
          origin: 'Cilacap',
          destination: 'Bandung',
          shipmentStatus: ShipmentStatus.completed,
          conditionStatus: 'NORMAL',
          deviceId: 'ESP32-FSH002',
          isActive: false,
          departureTime:
              DateTime.now().subtract(const Duration(days: 1, hours: 6)),
          estimatedArrival: DateTime.now().subtract(const Duration(hours: 2)),
          driverName: 'Agus Pratama',
          vehiclePlate: 'D 8812 AB',
          notes: 'Delivered to Supermarket Distribution Center',
          targetTempMin: 0.0,
          targetTempMax: 4.0,
        ),
        Shipment(
          id: 'FSH003',
          product: 'Frozen Shrimp (Vannamei)',
          origin: 'Semarang',
          destination: 'Surabaya',
          shipmentStatus: ShipmentStatus.inTransit,
          conditionStatus: 'NORMAL',
          deviceId: 'ESP32-FSH003',
          isActive: false,
          departureTime: DateTime.now().subtract(const Duration(hours: 1)),
          estimatedArrival: DateTime.now().add(const Duration(hours: 7)),
          driverName: 'Hendro Wijaya',
          vehiclePlate: 'L 7719 XY',
          notes: 'Deep freeze container - maintain sub-zero condition',
          targetTempMin: -18.0,
          targetTempMax: -5.0,
        ),
        Shipment(
          id: 'FSH004',
          product: 'Live Mud Crab (Kepiting Bakau)',
          origin: 'Pontianak',
          destination: 'Jakarta',
          shipmentStatus: ShipmentStatus.scheduled,
          conditionStatus: 'NORMAL',
          deviceId: 'ESP32-FSH004',
          isActive: false,
          departureTime: DateTime.now().add(const Duration(hours: 4)),
          estimatedArrival: DateTime.now().add(const Duration(hours: 18)),
          driverName: 'Rian Hidayat',
          vehiclePlate: 'KB 5120 GH',
          notes: 'Air cargo transit with controlled humidity',
          targetTempMin: 12.0,
          targetTempMax: 18.0,
        ),
      ];
}
