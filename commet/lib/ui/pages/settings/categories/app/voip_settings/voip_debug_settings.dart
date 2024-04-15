import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/account_selector.dart';
import 'package:commet/ui/pages/settings/categories/app/voip_settings/voip_debug_matrix_client.dart';
import 'package:flutter/material.dart';

class VoipDebugSettings extends StatefulWidget {
  const VoipDebugSettings({super.key});

  @override
  State<VoipDebugSettings> createState() => _VoipDebugSettingsState();
}

class _VoipDebugSettingsState extends State<VoipDebugSettings> {
  late Client selectedClient;

  @override
  void initState() {
    selectedClient = clientManager!.clients.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (clientManager!.clients.length > 1)
          AccountSelector(
            clientManager!.clients,
            onClientSelected: (client) {
              setState(() {
                selectedClient = client;
              });
            },
          ),
        if (selectedClient is MatrixClient)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: VoipDebugMatrixClient(selectedClient as MatrixClient),
          )
      ],
    );
  }
}
