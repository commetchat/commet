import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/stale_info.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/pages/login/login_page.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/config/config.dart';
import 'package:scaled_app/scaled_app.dart';

class SettingsCategoryAccount implements SettingsCategory {
  @override
  List<SettingsTab> get tabs => List.from([
        SettingsTab(
            label: T.current.settingsTabManageAccounts,
            pageBuilder: (context) {
              return AccountManagementSettingsTab(
                clientManager: Provider.of<ClientManager>(context),
              );
            }),
      ]);

  @override
  String get title => T.current.settingsCategoryAccount;
}

class AccountManagementSettingsTab extends StatefulWidget {
  const AccountManagementSettingsTab({super.key, required this.clientManager});
  static ValueKey addAccountKey = ValueKey("ACCOUNT_MANAGEMENT_SETTINGS_ADD_ACCOUNT_BUTTON");
  final ClientManager clientManager;
  @override
  State<AccountManagementSettingsTab> createState() => _AccountManagementSettingsTabState();
}

class _AccountManagementSettingsTabState extends State<AccountManagementSettingsTab> {
  StreamSubscription<int>? onClientAddedListener;
  StreamSubscription<StalePeerInfo>? onClientRemovedListener;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late int _numClients;

  @override
  Widget build(BuildContext context) {
    return manageAccountsTab(context);
  }

  @override
  void initState() {
    onClientAddedListener = widget.clientManager.onClientAdded?.stream.listen((index) {
      _listKey.currentState?.insertItem(index);
      setState(() {
        _numClients++;
      });
    });

    onClientRemovedListener = widget.clientManager.onClientRemoved?.stream.listen((info) {
      _listKey.currentState?.removeItem(
          info.index,
          (context, animation) => SizeTransition(
                sizeFactor: animation,
                child: accountListItem(displayName: info.displayName!, avatar: info.avatar, detail: info.identifier),
              ));
    });

    _numClients = widget.clientManager.clients.length;

    super.initState();
  }

  @override
  void dispose() {
    onClientAddedListener?.cancel();
    onClientRemovedListener?.cancel();
    super.dispose();
  }

  Widget manageAccountsTab(BuildContext context) {
    ClientManager clientManager = Provider.of<ClientManager>(context);

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Tile(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).extension<ExtraColors>()!.surfaceLow2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [accountListBuilder(context, clientManager), addAccountButton(context)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget accountListBuilder(BuildContext context, ClientManager clientmanager) {
    var clients = clientmanager.clients;

    return AnimatedList(
      initialItemCount: _numClients,
      shrinkWrap: true,
      key: _listKey,
      itemBuilder: (context, index, animation) {
        return SizeTransition(
          sizeFactor: animation,
          child: accountListItem(
              displayName: clients[index].user!.displayName,
              avatar: clients[index].user!.avatar,
              detail: clients[index].user!.identifier,
              onLogoutClicked: () => clientmanager.logoutClient(clients[index])),
        );
      },
    );
  }

  Widget accountListItem(
      {required String displayName, ImageProvider? avatar, String? detail, Function? onLogoutClicked}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 4, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          UserPanel(
            displayName: displayName,
            avatar: avatar,
            detail: detail,
          ),
          tiamat.Button.danger(
            text: "Logout",
            onTap: () {
              onLogoutClicked?.call();
            },
          )
        ],
      ),
    );
  }

  Padding addAccountButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 12, 12),
      child: Align(
          alignment: Alignment.centerRight,
          child: JustTheTooltip(
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: tiamat.Text("Add Account"),
            ),
            preferredDirection: AxisDirection.down,
            offset: 5,
            tailLength: 5,
            tailBaseWidth: 5,
            backgroundColor: Theme.of(context).extension<ExtraColors>()!.surfaceLow4,
            child: tiamat.CircleButton(
              key: AccountManagementSettingsTab.addAccountKey,
              icon: Icons.add,
              radius: 20,
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => LoginPage(
                          onSuccess: (_, newContext) {
                            Navigator.of(newContext).pop();
                          },
                        )));
              },
            ),
          )),
    );
  }
}
