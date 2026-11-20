import 'dart:async';

import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixFilteringSettingsTab extends StatefulWidget {
  const new({required this.client, super.key});
  final MatrixClient client;
  @override
  State<MatrixFilteringSettingsTab> createState() =>
      _MatrixFilteringSettingsTabState();
}

class _MatrixFilteringSettingsTabState
    extends State<MatrixFilteringSettingsTab> {
  List<String> blockedAccounts = List.empty();
  StreamSubscription? sub;

  String promptConfirmationUnblockUser(String user) => Intl.message(
    "Are you sure you want to unblock the user `$user`?",
    desc: "Confirmation text for the popup asking the user if they want to unblock another user",
    args: [user],
    name: "promptConfirmationUnblockUser",
  );

  String get labelNoUsersBlocked => Intl.message(
    "You have not blocked anyone!",
    name: "labelNoUsersBlocked",
    desc: "Label for the settings category Account",
  );

  String get headerBlockedAccounts => Intl.message(
    "Blocked Accounts",
    name: "headerBlockedAccounts",
    desc: "Header for the list of other users that you have blocked",
  );

  @override
  void initState() {
    blockedAccounts = widget.client.blockedUsers();

    sub = EventBus.userBlockStatusChanged.stream.listen(
      (_) => setState(() => blockedAccounts = widget.client.blockedUsers()),
    );

    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        tiamat.Panel(
          mode: tiamat.TileType.surfaceContainerLow,
          header: headerBlockedAccounts,
          child: Column(
            children: [
              if (blockedAccounts.isEmpty)
                SizedBox(
                  height: 80,
                  child: Center(
                    child: tiamat.Text.labelLow(labelNoUsersBlocked),
                  ),
                ),
              for (var i in blockedAccounts)
                SizedBox(height: 60, child: blockedAccount(i)),
            ],
          ),
        ),
      ],
    );
  }

  Widget blockedAccount(String userId) {
    return UserPanel(
      userId: userId,
      client: widget.client,
      contextRoom: null,
      onTap: () async {
        if (true ==
            await AdaptiveDialog.confirmation(
              context,
              prompt: promptConfirmationUnblockUser(userId),
              title: "Unblock?",
            )) {
          await widget.client.unblockUser(userId);
        }
      },
    );
  }
}
