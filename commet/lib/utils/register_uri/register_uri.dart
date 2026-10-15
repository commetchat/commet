import 'register_uri_stub.dart' if (dart.library.io) 'register_uri_io.dart';

Future<void> registerAppLinkHandlers() {
  return registerUriHandlers();
}
