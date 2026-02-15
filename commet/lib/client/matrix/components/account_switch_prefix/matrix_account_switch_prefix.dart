import 'package:commet/client/client.dart';
import 'package:commet/client/components/account_switch_prefix/account_switch_prefix.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';

class MatrixAccountSwitchComponent extends AccountSwitchPrefix<MatrixClient> {
  @override
  MatrixClient client;

  MatrixAccountSwitchComponent(this.client);

  static const accountDataKey = "im.fluffychat.account_bundles";

  @override
  String? get clientPrefix {
    final bundles = client.matrixClient.accountData[accountDataKey];
    final content = bundles?.content;
    final prefix = content?["prefix"];
    if (prefix is String) {
      return prefix;
    }

    return null;
  }

  @override
  (Client, String)? getPrefixedAccount(String string, Room currentRoom) {
    for (var otherClient in clientManager!.clients) {
      if (otherClient is! MatrixClient) continue;

      var component = otherClient.getComponent<AccountSwitchPrefix>();
      if (component == null) continue;

      if (component.clientPrefix == null) continue;

      if (string.startsWith(component.clientPrefix!)) {
        print("Found prefixed client!, $otherClient");

        if (otherClient.hasRoom(currentRoom.roomId)) {
          return (otherClient, component.clientPrefix!);
        } else {
          print("Client is not a member of the room!");
        }
      }
    }

    return null;
  }

  @override
  String removePrefix(String string, Room currentRoom) {
    var result = getPrefixedAccount(string, currentRoom);
    if (result == null) {
      return string;
    }

    var prefix = result.$2;

    if (string.startsWith(prefix)) {
      var result = string.substring(prefix.length);
      return result.trimLeft();
    } else {
      return string;
    }
  }

  @override
  Future<void> setClientPrefix(String? prefix) async {
    Log.d("Setting new account prefix: $prefix");

    final bundles = client.matrixClient.accountData[accountDataKey];
    final content = bundles?.content ?? {};

    if (prefix == null || prefix == "") {
      content.remove("prefix");
    } else {
      content["prefix"] = prefix.trim();
    }

    await client.matrixClient
        .setAccountData(client.matrixClient.userID!, accountDataKey, content);
  }

  @override
  bool isPossiblyUsingPrefix(String currentText) {
    for (var otherClient in clientManager!.clients) {
      if (otherClient is! MatrixClient) continue;

      var component = otherClient.getComponent<AccountSwitchPrefix>();
      if (component == null) continue;

      if (component.clientPrefix == null) continue;

      if (currentText.length >= component.clientPrefix!.length) {
        if (currentText.startsWith(component.clientPrefix!)) {
          return true;
        }
      } else {
        if (component.clientPrefix!.startsWith(currentText)) {
          return true;
        }
      }
    }

    return false;
  }
}
