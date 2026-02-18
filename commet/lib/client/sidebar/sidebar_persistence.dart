import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/sidebar/sidebar_data.dart';

class SidebarPersistence {
  static SidebarData readFromClient(Client client) {
    if (client is! MatrixClient) return SidebarData.empty();
    var data =
        client.matrixClient.accountData[SidebarData.accountDataType];
    if (data == null) return SidebarData.empty();
    return SidebarData.fromJson(data.content);
  }

  static Future<void> writeToClient(
      Client client, SidebarData data) async {
    if (client is! MatrixClient) return;
    await client.matrixClient.setAccountData(
      client.matrixClient.userID!,
      SidebarData.accountDataType,
      data.toJson(),
    );
  }

  static Future<void> writeToAllClients(
      List<Client> clients, SidebarData data) async {
    await Future.wait(
      clients.map((client) => writeToClient(client, data)),
    );
  }
}
