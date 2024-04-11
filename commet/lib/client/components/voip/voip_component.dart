import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:flutter/widgets.dart';

abstract class VoipComponent<T extends Client> implements Component<T> {}
