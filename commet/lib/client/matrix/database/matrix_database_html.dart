import 'package:commet/config/app_config.dart';
import 'package:matrix/matrix.dart';

import 'package:universal_html/html.dart' as html;

Future<DatabaseApi> getMatrixDatabaseImplementation(String clientName) async {
  await html.window.navigator.storage?.persist();
  var db = MatrixSdkDatabase(clientName);
  await db.open();
  return db;
}

Future<DatabaseApi> getLegacyMatrixDatabaseImplementation(
    String clientName) async {
  // ignore: deprecated_member_use
  final db = HiveCollectionsDatabase(
      clientName, await AppConfig.getHiveDatabasePath());
  await db.open();
  return db;
}
