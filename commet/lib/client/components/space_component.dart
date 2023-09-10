import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';

abstract class SpaceComponent<R extends Client, T extends Space>
    extends Component<R> {
  late T _space;
  T get space => _space;

  SpaceComponent(R client, T space) : super(client) {
    _space = space;
  }
}
