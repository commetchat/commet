import 'package:commet/client/components/petname/petname_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';

class MatrixPetNameComponent implements PetNameComponent<MatrixClient> {
  static const String key = 'chat.commet.petnames';

  @override
  MatrixClient client;

  MatrixPetNameComponent(this.client);

  @override
  String? getPetName(String identifier) {
    final content = client.matrixClient.accountData[key]?.content ?? const {};
    final value = content[identifier];
    return value is String && value.isNotEmpty ? value : null;
  }

  @override
  Future<void> setPetName(String identifier, String? name) async {
    final content = Map<String, dynamic>.from(
      client.matrixClient.accountData[key]?.content ?? const {},
    );

    if (name == null || name.trim().isEmpty) {
      content.remove(identifier);
    } else {
      content[identifier] = name.trim();
    }

    await client.matrixClient.setAccountData(
      client.matrixClient.userID!,
      key,
      content,
    );
  }
}
