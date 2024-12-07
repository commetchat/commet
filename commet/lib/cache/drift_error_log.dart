import 'package:commet/cache/app_data_db.dart';
import 'package:commet/cache/error_log.dart';

class DriftErrorLog implements ErrorLog {
  AppDataDB db;

  DriftErrorLog(this.db);

  @override
  Future<void> storeError(String stackTrace, String detail, String type) async {
    await db.transaction(() async {
      var data = await (db.select(db.errorLogEntry)
            ..where((tbl) => tbl.stackTrace.equals(stackTrace)))
          .getSingleOrNull();

      var newData = ErrorLogEntryData(
          stackTrace: stackTrace,
          detail: detail,
          lastOccurred: DateTime.now().millisecondsSinceEpoch,
          occurrences: data != null ? data.occurrences + 1 : 1);

      await db.into(db.errorLogEntry).insertOnConflictUpdate(newData);
    });
  }

  @override
  Future<List<ErrorEntry>> getErrors() async {
    final errors = await db.select(db.errorLogEntry).get();
    var list = errors
        .map((e) => ErrorEntry(
            stackTrace: e.stackTrace,
            detail: e.detail,
            lastOccurred: DateTime.fromMillisecondsSinceEpoch(e.lastOccurred),
            occurrences: e.occurrences))
        .toList();
    list.sort((a, b) => b.lastOccurred.compareTo(a.lastOccurred));
    return list;
  }
}
