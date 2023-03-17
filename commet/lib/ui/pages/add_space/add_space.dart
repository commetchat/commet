import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import 'add_space_view.dart';

class AddSpace extends StatefulWidget {
  const AddSpace({required this.clientManager, super.key});
  final ClientManager clientManager;
  @override
  State<AddSpace> createState() => AddSpaceState();
}

class AddSpaceState extends State<AddSpace> {
  void createSpace(Client client, String name, RoomVisibility visibility) {
    client.createSpace(name, visibility);
  }

  @override
  Widget build(BuildContext context) {
    return AddSpaceView(clients: widget.clientManager.getClients(), onCreateSpace: createSpace);
  }
}
