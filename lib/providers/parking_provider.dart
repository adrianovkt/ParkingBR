import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/payment_method.dart';
import '../models/ticket.dart';
import '../models/vehicle.dart';

class ParkingProvider extends ChangeNotifier {
  final List<Vehicle> _vehicles = [];
  final List<Ticket> _tickets = [];
  final List<PaymentMethod> _paymentMethods = [];
  static const _uuid = Uuid();

  ParkingProvider() {
    _loadDummyData();
  }

  List<Vehicle> get vehicles => _vehicles;
  List<Ticket> get tickets => _tickets;
  List<PaymentMethod> get paymentMethods => _paymentMethods;

  void addVehicle(Vehicle vehicle) {
    _vehicles.add(vehicle);
    notifyListeners();
  }

  // Check In (Create Ticket)
  Ticket checkIn(String vehicleId) {
    final ticket = Ticket(
      id: _uuid.v4(),
      vehicleId: vehicleId,
      entryTime: DateTime.now(),
      status: TicketStatus.active,
    );
    _tickets.add(ticket);
    notifyListeners();
    return ticket;
  }

  void checkOut(String ticketId, String paymentMethodId) {
    final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
    if (ticketIndex != -1) {
      final ticket = _tickets[ticketIndex];
      final cost = ticket.currentCost;

      _tickets[ticketIndex] = Ticket(
        id: ticket.id,
        vehicleId: ticket.vehicleId,
        entryTime: ticket.entryTime,
        exitTime: DateTime.now(),
        status: TicketStatus.completed,
        paidAmount: cost,
        paymentMethodId: paymentMethodId,
      );
      notifyListeners();
    }
  }

  Vehicle? getVehicle(String id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  Ticket? getActiveTicketForVehicle(String vehicleId) {
    try {
      return _tickets.firstWhere(
        (t) => t.vehicleId == vehicleId && t.status == TicketStatus.active,
      );
    } catch (e) {
      return null;
    }
  }

  void _loadDummyData() {
    final v1 = Vehicle(
      id: _uuid.v4(),
      plate: 'ABC-1234',
      model: 'Toyota Corolla',
      color: 'Silver',
      ownerName: 'João Silva',
      ownerCpf: '123.456.789-00',
      ownerContact: '(11) 98765-4321',
      ownerId: 'user-1',
    );

    final v2 = Vehicle(
      id: _uuid.v4(),
      plate: 'XYZ-9876',
      model: 'Honda Civic',
      color: 'Black',
      ownerName: 'Maria Oliveira',
      ownerCpf: '987.654.321-11',
      ownerContact: '(21) 91234-5678',
      ownerId: 'user-2',
    );

    _vehicles.addAll([v1, v2]);
    _tickets.add(
      Ticket(
        id: _uuid.v4(),
        vehicleId: v1.id,
        entryTime: DateTime.now().subtract(
          const Duration(hours: 2, minutes: 30),
        ),
        status: TicketStatus.active,
      ),
    );

    _paymentMethods.addAll([
      PaymentMethod(
        id: '1',
        name: 'Visa **** 4242',
        type: PaymentType.creditCard,
        icon: Icons.credit_card,
        color: Colors.blueAccent,
        details: '**** 4242',
      ),
      PaymentMethod(
        id: '2',
        name: 'Mastercard **** 5555',
        type: PaymentType.creditCard,
        icon: Icons.credit_card,
        color: Colors.orangeAccent,
        details: '**** 5555',
      ),
      PaymentMethod(
        id: '3',
        name: 'PIX',
        type: PaymentType.pix,
        icon: Icons.qr_code,
        color: Colors.green,
      ),
      PaymentMethod(
        id: '4',
        name: 'Cash',
        type: PaymentType.cash,
        icon: Icons.money,
        color: Colors.grey,
      ),
    ]);
  }
}
