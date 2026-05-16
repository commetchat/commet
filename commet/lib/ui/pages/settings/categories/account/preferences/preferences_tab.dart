import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/molecules/account_selector.dart';
import 'package:commet/ui/pages/settings/categories/account/preferences/preferences_chat_privacy.dart';
import 'package:flutter/material.dart';

class AccountSettingsTab extends StatefulWidget {
  const AccountSettingsTab({required this.clientManager, super.key});
  final ClientManager clientManager;

  @override
  State<AccountSettingsTab> createState() => _AccountSettingsTabState();
}

class _AccountSettingsTabState extends State<AccountSettingsTab> {
  late Client selectedClient;

  @override
  void initState() {
    selectedClient = widget.clientManager.clients.first;
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
          height: 4,
        ),
        ChatPrivacyPreferences(
            client: selectedClient,
            key: ValueKey(
                "chat-privacy-preferences_${selectedClient.identifier}")),
      ],
    );
  }
}
