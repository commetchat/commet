import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/ui/molecules/account_selector.dart';
import 'package:flutter/material.dart';

import 'matrix/matrix_security_tab.dart';

class SecuritySettingsTab extends StatefulWidget {
  const SecuritySettingsTab({required this.clientManager, super.key});
  final ClientManager clientManager;

  @override
  State<SecuritySettingsTab> createState() => _SecuritySettingsTabState();
}

class _SecuritySettingsTabState extends State<SecuritySettingsTab> {
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
        pickSecurityPage(selectedClient)
      ],
    );
  }

  Widget pickSecurityPage(Client client) {
    if (client is MatrixClient) {
      return MatrixSecurityTab(
        client,
        key: client.key,
      );
    }

    return const Placeholder();
  }
}
