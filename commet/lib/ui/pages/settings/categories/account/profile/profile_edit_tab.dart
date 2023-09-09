import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/pages/settings/categories/account/profile/profile_edit_view.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';

class ProfileEditTab extends StatefulWidget {
  const ProfileEditTab(
      {required this.clientManager, this.selectedClientIndex = 0, super.key});
  final ClientManager clientManager;
  final int selectedClientIndex;
  @override
  State<ProfileEditTab> createState() => _ProfileEditTabState();
}

class _ProfileEditTabState extends State<ProfileEditTab> {
  Client? selectedClient;

  @override
  void initState() {
    selectedClient = widget.clientManager.clients[widget.selectedClientIndex];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemBuilder: (context, index) {
        var client = widget.clientManager.clients[index];
        return Column(
          children: [
            ProfileEditView(
              avatar: client.self?.avatar,
              displayName: client.self!.displayName,
              identifier: client.self!.identifier,
              pickAvatar: (bytes, type) => pickAvatar(client, bytes, type),
              setDisplayName: (name) => setDisplayName(client, name),
              canEditName: true,
              canEditAvatar: true,
            ),
            const Seperator()
          ],
        );
      },
      itemCount: widget.clientManager.clients.length,
    );
  }

  void pickAvatar(Client client, Uint8List bytes, String? type) async {
    await client.setAvatar(bytes, type ?? "");
    setState(() {});
  }

  void setDisplayName(Client client, String name) async {
    await client.setDisplayName(name);
  }
}
