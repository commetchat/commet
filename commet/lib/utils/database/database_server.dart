import 'database_server_stub.dart'
    if (dart.library.io) 'database_server_io.dart';

Future<void> initDatabaseServer() async {
  await initDatabaseServerImpl();
}
