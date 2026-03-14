import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/payment_method.dart';
import '../models/ticket.dart';
import '../models/vehicle.dart';

class ParkingProvider extends ChangeNotifier {
  static const _keyVehicles = 'parking.vehicles';
  static const _keyTickets = 'parking.tickets';

  List<Vehicle> _vehicles = [];
  List<Ticket> _tickets = [];
  final List<PaymentMethod> _paymentMethods = [];
  static const _uuid = Uuid();
  bool _initialized = false;

  ParkingProvider() {
    _init();
  }

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  List<Ticket> get tickets => List.unmodifiable(_tickets);
  List<PaymentMethod> get paymentMethods => List.unmodifiable(_paymentMethods);
  bool get initialized => _initialized;

  // Inicializa os dados do provedor
  Future<void> _init() async {
    await _loadFromPrefs();
    _loadPaymentMethods();
    _initialized = true;
    notifyListeners();
  }

  // Carrega veículos e tickets salvos localmente
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final vehiclesJson = prefs.getString(_keyVehicles);
      if (vehiclesJson != null) {
        final List<dynamic> list = jsonDecode(vehiclesJson);
        _vehicles = list.map((v) => Vehicle.fromJson(v)).toList();
      }

      final ticketsJson = prefs.getString(_keyTickets);
      if (ticketsJson != null) {
        final List<dynamic> list = jsonDecode(ticketsJson);
        _tickets = list.map((t) => Ticket.fromJson(t)).toList();
      }

      if (_vehicles.isEmpty) {
        _loadDummyData();
        await _saveToPrefs();
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
    }
  }

  // Salva os dados atuais no armazenamento local
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyVehicles, jsonEncode(_vehicles.map((v) => v.toJson()).toList()));
      await prefs.setString(_keyTickets, jsonEncode(_tickets.map((t) => t.toJson()).toList()));
    } catch (e) {
      debugPrint('Erro ao salvar dados: $e');
    }
  }

  // Adiciona um novo veículo
  Future<void> addVehicle(Vehicle vehicle) async {
    _vehicles.add(vehicle);
    notifyListeners();
    await _saveToPrefs();
  }

  // Atualiza informações de um veículo existente
  Future<void> updateVehicle(Vehicle updatedVehicle) async {
    final index = _vehicles.indexWhere((v) => v.id == updatedVehicle.id);
    if (index != -1) {
      _vehicles[index] = updatedVehicle;
      notifyListeners();
      await _saveToPrefs();
    }
  }

  // Remove um veículo e seus tickets ativos
  Future<void> deleteVehicle(String vehicleId) async {
    _vehicles.removeWhere((v) => v.id == vehicleId);
    _tickets.removeWhere((t) => t.vehicleId == vehicleId && t.status == TicketStatus.active);
    notifyListeners();
    await _saveToPrefs();
  }

  Vehicle? getVehicle(String id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  // Realiza o check-in de um veículo
  Future<Ticket> checkIn(String vehicleId) async {
    final existing = getActiveTicketForVehicle(vehicleId);
    if (existing != null) return existing;

    final ticket = Ticket(
      id: _uuid.v4(),
      vehicleId: vehicleId,
      entryTime: DateTime.now(),
      status: TicketStatus.active,
    );
    _tickets.add(ticket);
    notifyListeners();
    await _saveToPrefs();
    return ticket;
  }

  // Realiza o check-out e registra o pagamento
  Future<void> checkOut(String ticketId, String paymentMethodId) async {
    final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
    if (ticketIndex != -1) {
      final ticket = _tickets[ticketIndex];
      _tickets[ticketIndex] = Ticket(
        id: ticket.id,
        vehicleId: ticket.vehicleId,
        entryTime: ticket.entryTime,
        exitTime: DateTime.now(),
        status: TicketStatus.completed,
        paidAmount: ticket.currentCost,
        paymentMethodId: paymentMethodId,
      );
      notifyListeners();
      await _saveToPrefs();
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

  // Define os métodos de pagamento disponíveis
  void _loadPaymentMethods() {
    _paymentMethods.clear();
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
        name: 'Dinheiro',
        type: PaymentType.cash,
        icon: Icons.money,
        color: Colors.grey,
      ),
    ]);
  }

  // Carrega dados iniciais de exemplo
  void _loadDummyData() {
    final v1 = Vehicle(
      id: _uuid.v4(),
      plate: 'ABC-1234',
      model: 'Toyota Corolla',
      color: 'Prata',
      ownerName: 'João Silva',
      ownerCpf: '123.456.789-00',
      ownerContact: '(11) 98765-4321',
      ownerId: 'user-1',
    );
    _vehicles.add(v1);
  }
}
