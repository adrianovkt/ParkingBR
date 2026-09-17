import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../models/ticket.dart';
import '../../../models/vehicle.dart';
import '../../../utils/plate_validator.dart';
import '../domain/pricing.dart';
import 'parking_database.dart';

class ParkingRepository {
  static const _legacyVehiclesKey = 'parking.vehicles';
  static const _legacyTicketsKey = 'parking.tickets';
  static const _migrationKey = 'legacy_json_migrated';
  static const _uuid = Uuid();
  static const _receivedViaValues = {'cash', 'pix', 'card', 'free'};

  final DatabaseFactory _databaseFactory;
  final String? databasePath;
  Database? _database;

  ParkingRepository({
    DatabaseFactory? databaseFactoryOverride,
    this.databasePath,
  }) : _databaseFactory = databaseFactoryOverride ?? databaseFactory;

  Future<void> initialize() async {
    if (_database != null) return;
    final database = await ParkingDatabase(
      databaseFactory: _databaseFactory,
      path: databasePath,
    ).open();
    try {
      _database = database;
      await _migrateLegacyData();
    } on Object {
      await database.close();
      _database = null;
      rethrow;
    }
  }

  Future<List<Vehicle>> loadVehicles() async {
    final database = await _getDatabase();
    final rows = await database.query(
      'vehicles',
      orderBy: 'archived ASC, plate ASC',
    );
    return rows.map(Vehicle.fromDatabase).toList(growable: false);
  }

  Future<List<Ticket>> loadTickets() async {
    final database = await _getDatabase();
    final rows = await database.query(
      'stays',
      orderBy: 'entered_at_ms DESC, id DESC',
    );
    return rows.map(Ticket.fromDatabase).toList(growable: false);
  }

  Future<int> migrationConflictCount() async {
    final database = await _getDatabase();
    final result = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM migration_conflicts',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Ticket> registerEntry({
    required Vehicle vehicle,
    required PricingPolicy pricing,
    DateTime? enteredAt,
  }) async {
    pricing.validate();
    final plate = PlateValidator.canonical(vehicle.plate);
    _validatePlate(plate);
    final database = await _getDatabase();
    final entry = (enteredAt ?? DateTime.now()).toUtc();

    return database.transaction((transaction) async {
      final matches = await transaction.query(
        'vehicles',
        where: 'plate = ?',
        whereArgs: [plate],
        limit: 1,
      );
      final vehicleId = matches.isEmpty
          ? vehicle.id
          : matches.single['id']! as String;

      if (matches.isEmpty) {
        await transaction.insert(
          'vehicles',
          vehicle.copyWith(plate: plate).toDatabase(),
        );
      } else {
        final existing = Vehicle.fromDatabase(matches.single);
        await transaction.update(
          'vehicles',
          existing
              .copyWith(
                model: _preferProvided(vehicle.model, existing.model),
                color: _preferProvided(vehicle.color, existing.color),
                ownerName: _preferProvided(
                  vehicle.ownerName,
                  existing.ownerName,
                ),
                ownerCpf: _preferProvided(vehicle.ownerCpf, existing.ownerCpf),
                ownerContact: _preferProvided(
                  vehicle.ownerContact,
                  existing.ownerContact,
                ),
                archived: false,
              )
              .toDatabase(),
          where: 'id = ?',
          whereArgs: [vehicleId],
        );
      }

      final openStay = await transaction.query(
        'stays',
        where: 'vehicle_id = ? AND exited_at_ms IS NULL',
        whereArgs: [vehicleId],
        limit: 1,
      );
      if (openStay.isNotEmpty) {
        throw StateError('Este veículo já está no pátio');
      }

      final ticket = Ticket(
        id: _uuid.v4(),
        vehicleId: vehicleId,
        plateAtEntry: plate,
        entryTime: entry,
        graceSeconds: pricing.graceSeconds,
        firstHourCents: pricing.firstHourCents,
        extraHourCents: pricing.extraHourCents,
      );
      await transaction.insert('stays', _ticketToDatabase(ticket));
      return ticket;
    });
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    final plate = PlateValidator.canonical(vehicle.plate);
    _validatePlate(plate);
    final database = await _getDatabase();
    final updated = await database.update(
      'vehicles',
      vehicle.copyWith(plate: plate).toDatabase(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
    if (updated == 0) {
      throw StateError('Veículo não encontrado');
    }
  }

  Future<void> archiveVehicle(String vehicleId) async {
    final database = await _getDatabase();
    await database.transaction((transaction) async {
      final openStay = await transaction.query(
        'stays',
        columns: ['id'],
        where: 'vehicle_id = ? AND exited_at_ms IS NULL',
        whereArgs: [vehicleId],
        limit: 1,
      );
      if (openStay.isNotEmpty) {
        throw StateError('Encerre a permanência antes de arquivar o veículo');
      }
      final updated = await transaction.update(
        'vehicles',
        {'archived': 1},
        where: 'id = ?',
        whereArgs: [vehicleId],
      );
      if (updated == 0) {
        throw StateError('Veículo não encontrado');
      }
    });
  }

  Future<Ticket> checkInExisting({
    required Vehicle vehicle,
    required PricingPolicy pricing,
    DateTime? enteredAt,
  }) {
    return registerEntry(
      vehicle: vehicle,
      pricing: pricing,
      enteredAt: enteredAt,
    );
  }

  Future<Ticket> closeStay({
    required String ticketId,
    required String receivedVia,
    DateTime? exitedAt,
  }) async {
    if (!_receivedViaValues.contains(receivedVia)) {
      throw ArgumentError('Forma de recebimento inválida');
    }
    final database = await _getDatabase();

    return database.transaction((transaction) async {
      final matches = await transaction.query(
        'stays',
        where: 'id = ?',
        whereArgs: [ticketId],
        limit: 1,
      );
      if (matches.isEmpty) {
        throw StateError('Permanência não encontrada');
      }

      final current = Ticket.fromDatabase(matches.single);
      if (current.exitTime != null) return current;

      final exit = (exitedAt ?? DateTime.now()).toUtc();
      final amountCents = receivedVia == 'free'
          ? 0
          : current.currentCostCents(exit);
      await transaction.update(
        'stays',
        {
          'exited_at_ms': exit.millisecondsSinceEpoch,
          'amount_cents': amountCents,
          'received_via': receivedVia,
        },
        where: 'id = ? AND exited_at_ms IS NULL',
        whereArgs: [ticketId],
      );
      return Ticket(
        id: current.id,
        vehicleId: current.vehicleId,
        plateAtEntry: current.plateAtEntry,
        entryTime: current.entryTime,
        exitTime: exit,
        graceSeconds: current.graceSeconds,
        firstHourCents: current.firstHourCents,
        extraHourCents: current.extraHourCents,
        pricingOrigin: current.pricingOrigin,
        amountCents: amountCents,
        receivedVia: receivedVia,
      );
    });
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<Database> _getDatabase() async {
    await initialize();
    return _database!;
  }

  Future<void> _migrateLegacyData() async {
    final database = _database!;
    final migrated = await database.query(
      'app_metadata',
      where: 'key = ?',
      whereArgs: [_migrationKey],
      limit: 1,
    );
    if (migrated.isNotEmpty) return;

    final preferences = await SharedPreferences.getInstance();
    final vehiclesJson = preferences.getString(_legacyVehiclesKey);
    final ticketsJson = preferences.getString(_legacyTicketsKey);
    if (vehiclesJson == null && ticketsJson == null) {
      await _markMigrationComplete(database);
      return;
    }

    if (vehiclesJson != null) {
      final saved = await preferences.setString(
        'parking.legacyBackup.vehicles',
        vehiclesJson,
      );
      if (!saved) throw StateError('Não foi possível criar o backup legado');
    }
    if (ticketsJson != null) {
      final saved = await preferences.setString(
        'parking.legacyBackup.tickets',
        ticketsJson,
      );
      if (!saved) throw StateError('Não foi possível criar o backup legado');
    }

    final decodeConflicts =
        <({String source, String reason, Map<String, dynamic> payload})>[];
    final vehicleItems = _decodeList(
      vehiclesJson,
      source: 'vehicle',
      conflicts: decodeConflicts,
    );
    final ticketItems = _decodeList(
      ticketsJson,
      source: 'ticket',
      conflicts: decodeConflicts,
    );
    await database.transaction((transaction) async {
      for (final conflict in decodeConflicts) {
        await _recordConflict(
          transaction,
          source: conflict.source,
          reason: conflict.reason,
          payload: conflict.payload,
        );
      }
      final vehicleIdMap = <String, String>{};
      final plateToId = <String, String>{};
      final importedVehicles = <String, Vehicle>{};

      for (final item in vehicleItems) {
        try {
          final vehicle = Vehicle.fromJson(item);
          final plate = PlateValidator.canonical(vehicle.plate);
          _validatePlate(plate);
          final existingId = plateToId[plate];
          if (existingId != null) {
            vehicleIdMap[vehicle.id] = existingId;
            await _recordConflict(
              transaction,
              source: 'vehicle',
              reason: 'Placa duplicada; cadastro associado ao primeiro ID',
              payload: item,
            );
            continue;
          }

          final normalized = vehicle.copyWith(plate: plate);
          await transaction.insert('vehicles', normalized.toDatabase());
          vehicleIdMap[vehicle.id] = vehicle.id;
          plateToId[plate] = vehicle.id;
          importedVehicles[vehicle.id] = normalized;
        } on Object catch (error) {
          await _recordConflict(
            transaction,
            source: 'vehicle',
            reason: error.toString(),
            payload: item,
          );
        }
      }

      final openVehicleIds = <String>{};
      for (final item in ticketItems) {
        try {
          final legacyTicket = Ticket.fromJson(item);
          final vehicleId =
              vehicleIdMap[legacyTicket.vehicleId] ?? legacyTicket.vehicleId;
          final vehicle = importedVehicles[vehicleId];
          if (vehicle == null) {
            throw StateError('Ticket sem veículo válido');
          }
          if (legacyTicket.exitTime == null && !openVehicleIds.add(vehicleId)) {
            throw StateError('Mais de uma permanência aberta para o veículo');
          }
          final normalized = Ticket(
            id: legacyTicket.id,
            vehicleId: vehicleId,
            plateAtEntry: vehicle.plate,
            entryTime: legacyTicket.entryTime.toUtc(),
            exitTime: legacyTicket.exitTime?.toUtc(),
            pricingOrigin: PricingOrigin.legacyDefault,
            amountCents: legacyTicket.amountCents,
            receivedVia: legacyTicket.receivedVia,
          );
          await transaction.insert('stays', _ticketToDatabase(normalized));
        } on Object catch (error) {
          await _recordConflict(
            transaction,
            source: 'ticket',
            reason: error.toString(),
            payload: item,
          );
        }
      }

      await transaction.insert('app_metadata', {
        'key': _migrationKey,
        'value': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  List<Map<String, dynamic>> _decodeList(
    String? value, {
    required String source,
    required List<
      ({String source, String reason, Map<String, dynamic> payload})
    >
    conflicts,
  }) {
    if (value == null || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) {
        throw const FormatException('Dados legados não são uma lista');
      }
      final items = <Map<String, dynamic>>[];
      for (var index = 0; index < decoded.length; index++) {
        final item = decoded[index];
        if (item is Map) {
          items.add(Map<String, dynamic>.from(item));
        } else {
          conflicts.add((
            source: source,
            reason: 'Registro legado não é um objeto',
            payload: {'index': index, 'value': item},
          ));
        }
      }
      return items;
    } on Object catch (error) {
      conflicts.add((
        source: source,
        reason: error.toString(),
        payload: {'raw': value},
      ));
      return const [];
    }
  }

  Future<void> _markMigrationComplete(Database database) async {
    await database.insert('app_metadata', {
      'key': _migrationKey,
      'value': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _recordConflict(
    DatabaseExecutor database, {
    required String source,
    required String reason,
    required Map<String, dynamic> payload,
  }) async {
    await database.insert('migration_conflicts', {
      'source': source,
      'reason': reason,
      'payload': jsonEncode(payload),
    });
  }

  void _validatePlate(String plate) {
    if (PlateValidator.identify(plate) == PlateType.invalid) {
      throw ArgumentError('Informe uma placa válida');
    }
  }

  String _preferProvided(String incoming, String existing) {
    final value = incoming.trim();
    return value.isEmpty ? existing : value;
  }

  Map<String, Object?> _ticketToDatabase(Ticket ticket) => {
    'id': ticket.id,
    'vehicle_id': ticket.vehicleId,
    'plate_at_entry': ticket.plateAtEntry,
    'entered_at_ms': ticket.entryTime.toUtc().millisecondsSinceEpoch,
    'exited_at_ms': ticket.exitTime?.toUtc().millisecondsSinceEpoch,
    'grace_seconds': ticket.graceSeconds,
    'first_hour_cents': ticket.firstHourCents,
    'extra_hour_cents': ticket.extraHourCents,
    'pricing_origin': switch (ticket.pricingOrigin) {
      PricingOrigin.configured => 'configured',
      PricingOrigin.legacyDefault => 'legacy_default',
    },
    'amount_cents': ticket.amountCents,
    'received_via': ticket.receivedVia,
  };
}
