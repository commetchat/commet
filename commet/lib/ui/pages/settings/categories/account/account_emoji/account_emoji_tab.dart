import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/pages/settings/categories/account/account_emoji/account_emoji_view.dart';
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
        if (selectedClient!.globalPacks.isNotEmpty)
          AccountEmojiView(
              selectedClient!.globalPacks, selectedClient!.personalPacks)
      ],
    );
  }
}
