import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';

abstract class DonationAwardsComponent<T extends Client>
    implements Component<T> {
  Future<String?> getClientSecret();
}
