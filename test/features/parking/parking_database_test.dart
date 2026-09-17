import 'package:flutter_test/flutter_test.dart';
import 'package:parking_br/features/parking/data/parking_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await ParkingDatabase(
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    ).open();
    await database.insert('vehicles', {
      'id': 'vehicle-1',
      'plate': 'ABC1234',
      'model': '',
      'color': '',
      'owner_name': '',
      'owner_cpf': '',
      'owner_contact': '',
      'archived': 0,
    });
  });

  tearDown(() => database.close());

  test(
    'o banco impede duas permanências abertas para o mesmo veículo',
    () async {
      await database.insert('stays', _openStay('stay-1'));

      await expectLater(
        database.insert('stays', _openStay('stay-2')),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test('o banco rejeita método de recebimento desconhecido', () async {
    await expectLater(
      database.insert('stays', {
        ..._openStay('stay-1'),
        'exited_at_ms': 2000,
        'amount_cents': 1000,
        'received_via': 'crypto',
      }),
      throwsA(isA<DatabaseException>()),
    );
  });
}

Map<String, Object?> _openStay(String id) => {
  'id': id,
  'vehicle_id': 'vehicle-1',
  'plate_at_entry': 'ABC1234',
  'entered_at_ms': 1000,
  'exited_at_ms': null,
  'grace_seconds': 900,
  'first_hour_cents': 1000,
  'extra_hour_cents': 500,
  'pricing_origin': 'configured',
  'amount_cents': null,
  'received_via': null,
};
