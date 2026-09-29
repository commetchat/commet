import 'package:matrix/matrix.dart';

Future<DatabaseApi> getMatrixDatabaseImplementation(String clientName,
    {bool onDatabaseIsolate = true, bool readOnly = false}) async {
  throw UnimplementedError();
}

Future<DatabaseApi?> getLegacyMatrixDatabaseImplementation(
    String clientName) async {
  throw UnimplementedError();
}
