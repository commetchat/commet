import 'package:matrix/matrix.dart';

class MatrixSdkDatabaseWrapper extends MatrixSdkDatabase {
  MatrixSdkDatabaseWrapper(
    super.name, {
    super.database,
    super.idbFactory,
    super.maxFileSize = 0,
    super.fileStoragePath,
    super.deleteFilesAfterDuration,
  });

  // Workaround for: https://github.com/commetchat/commet/issues/195
  // Just dont fetch events from database. Don't particularly love this but better than timeline gaps!
  @override
  Future<List<Event>> getEventList(Room room,
      {int start = 0, bool onlySending = false, int? limit}) async {
    return [];
  }
}
