import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/simulated/components/simulated_component.dart';
import 'package:commet/client/simulated/simulated_client.dart';
import 'package:test/test.dart';

void main() async {
  SimulatedClient client = SimulatedClient();

  test("Get Component", () {
    var component = client.getComponent<SimulatedComponent>();
    expect(component, isNotNull);
    expect(component is SimulatedComponent, isTrue);
  });

  test("Get Emoticon Component", () {
    var component = client.getComponent<EmoticonComponent>();
    expect(component, isNotNull);
    expect(component is EmoticonComponent, isTrue);

    expect(component!.client, equals(client));
  });
}
