import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/ui/molecules/account_selector.dart';
import 'package:commet/ui/pages/settings/categories/account/filtering/matrix_filtering_tab.dart';
import 'package:flutter/material.dart';

class FilteringSettingsTab extends StatefulWidget {
  const new({required this.clientManager, super.key});
  final ClientManager clientManager;

  @override
  State<FilteringSettingsTab> createState() => _FilteringSettingsTabState();
}

class _FilteringSettingsTabState extends State<FilteringSettingsTab> {
  late Client selectedClient;

  @override
  void initState() {
    selectedClient = widget.clientManager.clients.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
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
        pickSecurityPage(selectedClient),
      ],
    );
  }

  Widget pickSecurityPage(Client client) {
    if (client is MatrixClient) {
      return MatrixFilteringSettingsTab(client: client, key: client.key);
    }

    return const Placeholder();
  }
}
