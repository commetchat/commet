import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/ui/pages/settings/categories/account/account_emoji/account_emoji_view.dart';
import 'package:commet/ui/pages/settings/categories/room/emoji_packs/room_emoji_pack_settings_view.dart';
import 'package:flutter/widgets.dart';

import '../../../../../molecules/account_selector.dart';

class AccountEmojiTab extends StatefulWidget {
  const AccountEmojiTab(
      {required this.clientManager, this.selectedClientIndex = 0, super.key});
  final ClientManager clientManager;
  final int selectedClientIndex;
  @override
  State<AccountEmojiTab> createState() => _AccountEmojiTabState();
}

class _AccountEmojiTabState extends State<AccountEmojiTab> {
  Client? selectedClient;

  @override
  void initState() {
    selectedClient = widget.clientManager.clients[widget.selectedClientIndex];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.clientManager.clients.length > 1)
          AccountSelector(
            widget.clientManager.clients,
            onClientSelected: (client) {
              setState(() {
                selectedClient = client;
              });
            },
          ),
        const SizedBox(
          height: 10,
        ),
        buildEmojiView(context)
      ],
    );
  }

  Widget buildEmojiView(BuildContext context) {
    if (selectedClient?.emoticons == null) {
      return const Placeholder();
    }

    return Column(
      children: [
        RoomEmojiPackSettingsView(selectedClient!.emoticons!.ownedPacks,
            createNewPack: createPack,
            defaultExpanded: true,
            canCreatePack: selectedClient!.emoticons!.canCreatePack,
            deleteEmoticon: deleteEmoticon,
            deletePack: deletePack,
            renameEmoticon: renameEmoticon,
            onPackCreated: selectedClient!.emoticons!.onOwnedPackAdded),
        const SizedBox(
          height: 5,
        ),
        AccountEmojiView(selectedClient!.emoticons!.globalPacks(),
            selectedClient!.emoticons!.ownedPacks),
      ],
    );
  }

  Future<void> createPack(String name, Uint8List? avatarData) {
    return selectedClient!.emoticons!.createEmoticonPack(name, avatarData);
  }

  Future<void> renameEmoticon(
      EmoticonPack pack, Emoticon emoticon, String name) {
    return pack.renameEmoticon(emoticon, name);
  }

  Future<void> deleteEmoticon(EmoticonPack pack, Emoticon emoticon) {
    return pack.deleteEmoticon(emoticon);
  }

  Future<void> deletePack(EmoticonPack pack) {
    return selectedClient!.emoticons!.deleteEmoticonPack(pack);
  }
}
