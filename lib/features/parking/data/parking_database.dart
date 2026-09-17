import 'package:sqflite/sqflite.dart';

class ParkingDatabase {
  static const schemaVersion = 1;
  static const fileName = 'parking_br.db';

  final DatabaseFactory databaseFactory;
  final String? path;

  const ParkingDatabase({required this.databaseFactory, this.path});

  Future<Database> open() async {
    final databasePath = path ?? '${await getDatabasesPath()}/$fileName';
    return databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE vehicles (
              id TEXT PRIMARY KEY NOT NULL,
              plate TEXT NOT NULL UNIQUE CHECK(length(plate) = 7),
              model TEXT NOT NULL DEFAULT '',
              color TEXT NOT NULL DEFAULT '',
              owner_name TEXT NOT NULL DEFAULT '',
              owner_cpf TEXT NOT NULL DEFAULT '',
              owner_contact TEXT NOT NULL DEFAULT '',
              archived INTEGER NOT NULL DEFAULT 0 CHECK(archived IN (0, 1))
            )
          ''');
          await database.execute('''
            CREATE TABLE stays (
              id TEXT PRIMARY KEY NOT NULL,
              vehicle_id TEXT NOT NULL
                REFERENCES vehicles(id) ON DELETE RESTRICT,
              plate_at_entry TEXT NOT NULL,
              entered_at_ms INTEGER NOT NULL,
              exited_at_ms INTEGER,
              grace_seconds INTEGER NOT NULL
                CHECK(grace_seconds BETWEEN 0 AND 3600),
              first_hour_cents INTEGER NOT NULL CHECK(first_hour_cents >= 0),
              extra_hour_cents INTEGER NOT NULL CHECK(extra_hour_cents >= 0),
              pricing_origin TEXT NOT NULL
                CHECK(pricing_origin IN ('configured', 'legacy_default')),
              amount_cents INTEGER,
              received_via TEXT
                CHECK(received_via IN ('cash', 'pix', 'card', 'free')),
              CHECK(exited_at_ms IS NULL OR exited_at_ms >= entered_at_ms),
              CHECK(
                (
                  exited_at_ms IS NULL
                  AND amount_cents IS NULL
                  AND received_via IS NULL
                )
                OR
                (
                  exited_at_ms IS NOT NULL
                  AND amount_cents IS NOT NULL
                  AND amount_cents >= 0
                  AND received_via IS NOT NULL
                )
              )
            )
          ''');
          await database.execute('''
            CREATE UNIQUE INDEX one_open_stay_per_vehicle
            ON stays(vehicle_id) WHERE exited_at_ms IS NULL
          ''');
          await database.execute('''
            CREATE INDEX stays_by_entry
            ON stays(entered_at_ms DESC, id DESC)
          ''');
          await database.execute('''
            CREATE INDEX stays_by_exit
            ON stays(exited_at_ms DESC, id DESC)
            WHERE exited_at_ms IS NOT NULL
          ''');
          await database.execute('''
            CREATE TABLE app_metadata (
              key TEXT PRIMARY KEY NOT NULL,
              value TEXT NOT NULL
            )
          ''');
          await database.execute('''
            CREATE TABLE migration_conflicts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              source TEXT NOT NULL,
              reason TEXT NOT NULL,
              payload TEXT NOT NULL
            )
          ''');
        },
      ),
    );
  }
}
