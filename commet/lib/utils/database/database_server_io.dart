import 'package:commet/utils/database/multiple_database_server.dart';

Future<void>? initDatabaseServerImpl() async {
  await DatabaseIsolate.start();
}
