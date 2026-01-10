import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:flutter/widgets.dart';

abstract class UserColorComponent<T extends Client> implements Component<T> {
  Color? getColor(String identifier);

  Future<void> setColor(String identifier, Color? color);
}
