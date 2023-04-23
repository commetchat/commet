import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:flutter/widgets.dart';

import 'add_space_view.dart';

class AddSpace extends StatefulWidget {
  const AddSpace({required this.clientManager, super.key});
  final ClientManager clientManager;
  @override
  State<AddSpace> createState() => AddSpaceState();
}

class AddSpaceState extends State<AddSpace> {
  void createSpace(
      Client client, String name, RoomVisibility visibility) async {
    await client.createSpace(name, visibility);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void joinSpace(Client client, String address) async {
    await client.joinSpace(address);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AddSpaceView(
        clients: widget.clientManager.clients,
        onCreateSpace: createSpace,
        onJoinSpace: joinSpace);
  }
}
