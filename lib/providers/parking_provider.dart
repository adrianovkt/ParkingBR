import 'package:flutter/material.dart';

import '../features/parking/data/parking_repository.dart';
import '../features/parking/domain/pricing.dart';
import '../models/payment_method.dart';
import '../models/ticket.dart';
import '../models/vehicle.dart';

class ParkingProvider extends ChangeNotifier {
  final ParkingRepository _repository;

  List<Vehicle> _vehicles = const [];
  List<Ticket> _tickets = const [];
  bool _initialized = false;
  bool _loading = true;
  String? _initializationError;
  int _migrationConflictCount = 0;

  ParkingProvider({ParkingRepository? repository})
    : _repository = repository ?? ParkingRepository() {
    _initialize();
  }

  List<Vehicle> get vehicles =>
      _vehicles.where((vehicle) => !vehicle.archived).toList(growable: false);
  List<Vehicle> get allVehicles => List.unmodifiable(_vehicles);
  List<Ticket> get tickets => List.unmodifiable(_tickets);
  List<Ticket> get activeTickets => _tickets
      .where((ticket) => ticket.status == TicketStatus.active)
      .toList(growable: false);
  List<Ticket> get completedTickets {
    final tickets = _tickets
        .where((ticket) => ticket.status == TicketStatus.completed)
        .toList();
    tickets.sort((a, b) => b.exitTime!.compareTo(a.exitTime!));
    return tickets;
  }

  bool get initialized => _initialized;
  bool get loading => _loading;
  String? get initializationError => _initializationError;
  int get migrationConflictCount => _migrationConflictCount;

  List<PaymentMethod> get paymentMethods => const [
    PaymentMethod(
      id: 'cash',
      name: 'Dinheiro',
      type: PaymentType.cash,
      icon: Icons.payments_outlined,
      color: Colors.green,
    ),
    PaymentMethod(
      id: 'pix',
      name: 'PIX confirmado',
      type: PaymentType.pix,
      icon: Icons.qr_code_rounded,
      color: Colors.teal,
    ),
    PaymentMethod(
      id: 'card',
      name: 'Cartão na maquininha',
      type: PaymentType.card,
      icon: Icons.credit_card_rounded,
      color: Colors.indigo,
    ),
    PaymentMethod(
      id: 'free',
      name: 'Isento',
      type: PaymentType.free,
      icon: Icons.money_off_csred_outlined,
      color: Colors.orange,
    ),
  ];

  Future<void> _initialize() async {
    try {
      await _repository.initialize();
      await _reload();
      _migrationConflictCount = await _repository.migrationConflictCount();
      _initialized = true;
    } on Object catch (error) {
      _initializationError = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> retryInitialization() async {
    _loading = true;
    _initializationError = null;
    notifyListeners();
    await _initialize();
  }

  Future<Ticket> registerEntry({
    required Vehicle vehicle,
    required PricingPolicy pricing,
  }) async {
    final ticket = await _repository.registerEntry(
      vehicle: vehicle,
      pricing: pricing,
    );
    await _reload();
    return ticket;
  }

  Future<Ticket> checkIn(
    String vehicleId, {
    required PricingPolicy pricing,
  }) async {
    final vehicle = getVehicle(vehicleId);
    if (vehicle == null || vehicle.archived) {
      throw StateError('Veículo não encontrado');
    }
    final ticket = await _repository.checkInExisting(
      vehicle: vehicle,
      pricing: pricing,
    );
    await _reload();
    return ticket;
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _repository.updateVehicle(vehicle);
    await _reload();
  }

  Future<void> archiveVehicle(String vehicleId) async {
    await _repository.archiveVehicle(vehicleId);
    await _reload();
  }

  Future<Ticket> checkOut(String ticketId, String paymentMethodId) async {
    final ticket = await _repository.closeStay(
      ticketId: ticketId,
      receivedVia: paymentMethodId,
    );
    await _reload();
    return ticket;
  }

  Vehicle? getVehicle(String id) {
    for (final vehicle in _vehicles) {
      if (vehicle.id == id) return vehicle;
    }
    return null;
  }

  Ticket? getTicket(String id) {
    for (final ticket in _tickets) {
      if (ticket.id == id) return ticket;
    }
    return null;
  }

  Ticket? getActiveTicketForVehicle(String vehicleId) {
    for (final ticket in _tickets) {
      if (ticket.vehicleId == vehicleId &&
          ticket.status == TicketStatus.active) {
        return ticket;
      }
    }
    return null;
  }

  Future<void> _reload() async {
    final vehicles = await _repository.loadVehicles();
    final tickets = await _repository.loadTickets();
    _vehicles = vehicles;
    _tickets = tickets;
    notifyListeners();
  }
}
