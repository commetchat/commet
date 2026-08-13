import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/petname/petname_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';

class MatrixPetNameComponent
    implements PetNameComponent<MatrixClient>, NeedsPostLoginInit {
  static const String key = 'chat.commet.petnames';

  @override
  MatrixClient client;

  MatrixPetNameComponent(this.client);

  Map<String, dynamic> names = {};

  @override
  String? getPetName(String identifier) {
    final value = names[identifier];
    return value is String && value.isNotEmpty ? value : null;
  }

  @override
  Future<void> setPetName(String identifier, String? name) async {
    if (name == null || name.trim().isEmpty) {
      names.remove(identifier);
    } else {
      names[identifier] = name.trim();
    }

    await client.matrixClient
        .setAccountData(client.matrixClient.userID!, key, names);
  }

  @override
  void postLoginInit() {
    final data = client.matrixClient.accountData[key];
    names = data?.content ?? {};
  }
}
