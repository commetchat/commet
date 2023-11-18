import 'package:commet/client/client.dart';

abstract class Component<T extends Client> {
  final T client;
  Component(this.client);
}

abstract class NeedsPostLoginInit {
  void postLoginInit();
}
