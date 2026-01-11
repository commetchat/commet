import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';

class SecretClientIdentifier {
  String encryptedHash;
  String clientSecret;

  SecretClientIdentifier(
      {required this.encryptedHash, required this.clientSecret});
}

abstract class DonationAwardsComponent<T extends Client>
    implements Component<T> {
  Future<SecretClientIdentifier?> getClientSecret();
}
