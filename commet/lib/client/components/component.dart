import 'package:commet/client/client.dart';
import 'package:commet/main.dart';

abstract class Component<T extends Client> {
  final T client;
  Component(this.client);
}

abstract class NeedsPostLoginInit {
  void postLoginInit();

  static void doPostLoginInit() {
    for (var client in clientManager!.clients) {
      if (!client.isLoggedIn()) continue;

      var components = client.getAllComponents()!;

      for (var component in components) {
        if (component is! NeedsPostLoginInit) continue;

        (component as NeedsPostLoginInit).postLoginInit();
      }
    }
  }
}
