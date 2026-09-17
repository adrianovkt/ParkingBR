import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:parking_br/features/parking/data/parking_repository.dart';
import 'package:parking_br/features/parking/domain/pricing.dart';
import 'package:parking_br/models/ticket.dart';
import 'package:parking_br/models/vehicle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late ParkingRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = ParkingRepository(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    await repository.initialize();
  });

  tearDown(() => repository.close());

  test('cadastro e entrada são gravados juntos com tarifa congelada', () async {
    final entry = DateTime.parse('2026-01-01T12:00:00-03:00');
    final ticket = await repository.registerEntry(
      vehicle: _vehicle(plate: 'abc-1234'),
      pricing: const PricingPolicy(
        graceSeconds: 300,
        firstHourCents: 1200,
        extraHourCents: 600,
      ),
      enteredAt: entry,
    );

    final vehicles = await repository.loadVehicles();
    final tickets = await repository.loadTickets();
    expect(vehicles.single.plate, 'ABC1234');
    expect(tickets.single.id, ticket.id);
    expect(ticket.entryTime, entry.toUtc());
    expect(ticket.graceSeconds, 300);
    expect(ticket.firstHourCents, 1200);
    expect(ticket.extraHourCents, 600);
    expect(ticket.pricingOrigin, PricingOrigin.configured);
  });

  test('duplicidade não sobrescreve dados existentes do cadastro', () async {
    await repository.registerEntry(
      vehicle: _vehicle(model: 'Original'),
      pricing: const PricingPolicy(),
    );

    await expectLater(
      repository.registerEntry(
        vehicle: _vehicle(id: 'other-id', model: 'Alterado'),
        pricing: const PricingPolicy(),
      ),
      throwsStateError,
    );

    expect((await repository.loadVehicles()).single.model, 'Original');
    expect(await repository.loadTickets(), hasLength(1));
  });

  test(
    'nova permanência atualiza dados informados e preserva vazios',
    () async {
      final first = await repository.registerEntry(
        vehicle: _vehicle(),
        pricing: const PricingPolicy(),
      );
      await repository.closeStay(ticketId: first.id, receivedVia: 'cash');

      await repository.registerEntry(
        vehicle: _vehicle(
          id: 'other-id',
          model: 'Sedan',
          color: '',
          ownerName: '',
        ),
        pricing: const PricingPolicy(),
      );

      final vehicle = (await repository.loadVehicles()).single;
      expect(vehicle.id, 'vehicle-1');
      expect(vehicle.model, 'Sedan');
      expect(vehicle.color, 'Prata');
      expect(vehicle.ownerName, 'Cliente');
    },
  );

  test('falha no recebimento mantém a permanência aberta', () async {
    final entry = DateTime.utc(2026, 1, 1, 12);
    final ticket = await repository.registerEntry(
      vehicle: _vehicle(),
      pricing: const PricingPolicy(),
      enteredAt: entry,
    );

    await expectLater(
      repository.closeStay(
        ticketId: ticket.id,
        receivedVia: 'bitcoin',
        exitedAt: entry.add(const Duration(hours: 1)),
      ),
      throwsArgumentError,
    );
    await expectLater(
      repository.closeStay(
        ticketId: ticket.id,
        receivedVia: 'cash',
        exitedAt: entry.subtract(const Duration(seconds: 1)),
      ),
      throwsArgumentError,
    );

    expect((await repository.loadTickets()).single.exitTime, isNull);
  });

  test(
    'check-out repetido devolve o primeiro resultado sem nova cobrança',
    () async {
      final entry = DateTime.utc(2026, 1, 1, 12);
      final ticket = await repository.registerEntry(
        vehicle: _vehicle(),
        pricing: const PricingPolicy(),
        enteredAt: entry,
      );
      final first = await repository.closeStay(
        ticketId: ticket.id,
        receivedVia: 'cash',
        exitedAt: entry.add(const Duration(hours: 1, minutes: 1)),
      );
      final repeated = await repository.closeStay(
        ticketId: ticket.id,
        receivedVia: 'pix',
        exitedAt: entry.add(const Duration(hours: 5)),
      );

      expect(first.amountCents, 1500);
      expect(repeated.exitTime, first.exitTime);
      expect(repeated.amountCents, first.amountCents);
      expect(repeated.receivedVia, 'cash');
      expect(await repository.loadTickets(), hasLength(1));
    },
  );

  test('isenção encerra a permanência com valor zero', () async {
    final entry = DateTime.utc(2026, 1, 1, 12);
    final ticket = await repository.registerEntry(
      vehicle: _vehicle(),
      pricing: const PricingPolicy(),
      enteredAt: entry,
    );

    final closed = await repository.closeStay(
      ticketId: ticket.id,
      receivedVia: 'free',
      exitedAt: entry.add(const Duration(days: 2)),
    );

    expect(closed.amountCents, 0);
    expect(closed.receivedVia, 'free');
  });

  test('arquiva cadastro sem apagar a permanência concluída', () async {
    final ticket = await repository.registerEntry(
      vehicle: _vehicle(),
      pricing: const PricingPolicy(),
    );
    await expectLater(
      repository.archiveVehicle(ticket.vehicleId),
      throwsStateError,
    );
    await repository.closeStay(ticketId: ticket.id, receivedVia: 'cash');

    await repository.archiveVehicle(ticket.vehicleId);

    expect((await repository.loadVehicles()).single.archived, isTrue);
    expect(await repository.loadTickets(), hasLength(1));
  });

  test('dados sobrevivem ao fechamento e reabertura do banco', () async {
    await repository.close();
    final directory = await Directory.systemTemp.createTemp('parking_restart_');
    final path = '${directory.path}/parking.db';
    final first = ParkingRepository(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePath: path,
    );
    addTearDown(() async {
      await first.close();
      await directory.delete(recursive: true);
    });
    await first.initialize();
    await first.registerEntry(
      vehicle: _vehicle(),
      pricing: const PricingPolicy(),
    );
    await first.close();

    final reopened = ParkingRepository(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePath: path,
    );
    addTearDown(reopened.close);
    await reopened.initialize();

    expect(await reopened.loadVehicles(), hasLength(1));
    expect(await reopened.loadTickets(), hasLength(1));
  });

  test('migra JSON legado uma única vez e registra conflitos', () async {
    await repository.close();
    final directory = await Directory.systemTemp.createTemp('parking_migrate_');
    final path = '${directory.path}/parking.db';
    final legacyVehicles = [
      _vehicle().toJson(),
      _vehicle(id: 'duplicate', model: 'Duplicado').toJson(),
    ];
    final legacyTickets = [
      {
        'id': 'legacy-ticket',
        'vehicleId': 'vehicle-1',
        'entryTime': '2026-01-01T12:00:00-03:00',
        'exitTime': null,
        'paidAmount': 0,
        'paymentMethodId': null,
      },
    ];
    SharedPreferences.setMockInitialValues({
      'parking.vehicles': jsonEncode(legacyVehicles),
      'parking.tickets': jsonEncode(legacyTickets),
    });
    final migrated = ParkingRepository(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePath: path,
    );
    addTearDown(() async {
      await migrated.close();
      await directory.delete(recursive: true);
    });
    await migrated.initialize();

    expect(await migrated.loadVehicles(), hasLength(1));
    final tickets = await migrated.loadTickets();
    expect(tickets, hasLength(1));
    expect(tickets.single.pricingOrigin, PricingOrigin.legacyDefault);
    expect(await migrated.migrationConflictCount(), 1);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('parking.legacyBackup.vehicles'), isNotNull);
    expect(preferences.getString('parking.legacyBackup.tickets'), isNotNull);

    await migrated.close();
    final reopened = ParkingRepository(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePath: path,
    );
    addTearDown(reopened.close);
    await reopened.initialize();
    expect(await reopened.loadVehicles(), hasLength(1));
    expect(await reopened.loadTickets(), hasLength(1));
    expect(await reopened.migrationConflictCount(), 1);
  });

  test('isola JSON legado inválido sem bloquear os dados coerentes', () async {
    await repository.close();
    final directory = await Directory.systemTemp.createTemp(
      'parking_invalid_migrate_',
    );
    final path = '${directory.path}/parking.db';
    SharedPreferences.setMockInitialValues({
      'parking.vehicles': jsonEncode([_vehicle().toJson()]),
      'parking.tickets': '{invalid',
    });
    final migrated = ParkingRepository(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePath: path,
    );
    addTearDown(() async {
      await migrated.close();
      await directory.delete(recursive: true);
    });

    await migrated.initialize();

    expect(await migrated.loadVehicles(), hasLength(1));
    expect(await migrated.loadTickets(), isEmpty);
    expect(await migrated.migrationConflictCount(), 1);
  });
}

Vehicle _vehicle({
  String id = 'vehicle-1',
  String plate = 'ABC1234',
  String model = 'Hatch',
  String color = 'Prata',
  String ownerName = 'Cliente',
}) {
  return Vehicle(
    id: id,
    plate: plate,
    model: model,
    color: color,
    ownerName: ownerName,
    ownerCpf: '',
    ownerContact: '',
  );
}
