import 'package:commet/client/components/component.dart';
import 'package:commet/client/simulated/simulated_client.dart';

class SimulatedComponent extends Component<SimulatedClient> {
  SimulatedComponent(super.client);

  void doStuff() {
    // ignore: avoid_print
    print("Im stuff");
  }
}
