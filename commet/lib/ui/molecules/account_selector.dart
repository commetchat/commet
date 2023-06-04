import 'package:commet/client/client.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/widgets.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class AccountSelector extends StatelessWidget {
  const AccountSelector(this.clients, {super.key, this.onClientSelected});
  final List<Client> clients;
  final Function(Client client)? onClientSelected;

  @override
  Widget build(BuildContext context) {
    return tiamat.DropdownSelector<Client>(
      items: clients,
      itemHeight: 65,
      onItemSelected: (item) {
        onClientSelected?.call(item);
      },
      itemBuilder: (item) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          child: UserPanelView(
            displayName: item.user!.displayName,
            detail: item.user!.detail,
            avatar: item.user!.avatar,
          ),
        );
      },
    );
  }
}
