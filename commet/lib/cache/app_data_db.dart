import 'package:drift/drift.dart';
part 'app_data_db.g.dart';

class FileCacheEntry extends Table {
  TextColumn get id => text()();
  TextColumn get path => text()();

  IntColumn get lastAccessedTimestamp => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class ErrorLogEntry extends Table {
  TextColumn get stackTrace => text()();
  TextColumn get detail => text()();
  IntColumn get occurrences => integer()();
  IntColumn get lastOccurred => integer()();

  @override
  Set<Column> get primaryKey => {stackTrace};
}

@DriftDatabase(tables: [FileCacheEntry, ErrorLogEntry])
class AppDataDB extends _$AppDataDB {
  static const String isolateName = "chat.commet.commetapp.isolate.app_data";

  AppDataDB(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(errorLogEntry);
        }
      },
    );
  }
}
