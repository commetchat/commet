import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/pages/settings/categories/account/profile/profile_edit_view.dart';
import 'package:commet/utils/mime.dart';
import 'package:file_picker/file_picker.dart';
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
    return Flexible(
      child: SingleChildScrollView(
        child: ListView.builder(
          shrinkWrap: true,
          itemBuilder: (context, index) {
            var client = widget.clientManager.clients[index];
            return Column(
              children: [
                ProfileEditView(
                  avatar: client.user?.avatar,
                  displayName: client.user!.displayName,
                  identifier: client.user!.identifier,
                  pickAvatar: () => pickAvatar(client),
                  setDisplayName: (name) => setDisplayName(client, name),
                ),
                const Seperator()
              ],
            );
          },
          itemCount: widget.clientManager.clients.length,
        ),
      ),
    );
  }

  void pickAvatar(Client client) async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    if (result == null || result.count != 1) return;

    var type = Mime.fromExtenstion(result.files.first.extension!);
    if (type == null || result.files.first.bytes == null) return;

    await client.setAvatar(result.files.first.bytes!, type);
    setState(() {});
  }

  void setDisplayName(Client client, String name) async {
    await client.setDisplayName(name);
  }
}
