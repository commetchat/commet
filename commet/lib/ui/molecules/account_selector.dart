import 'package:commet/client/client.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/widgets.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class AccountSelector extends StatefulWidget {
  const AccountSelector(this.clients, {super.key, this.onClientSelected});
  final List<Client> clients;
  final Function(Client client)? onClientSelected;

  @override
  State<AccountSelector> createState() => _AccountSelectorState();
}

class _AccountSelectorState extends State<AccountSelector> {
  late Client selectedClient;

  @override
  void initState() {
    selectedClient = widget.clients.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return tiamat.DropdownSelector<Client>(
      items: widget.clients,
      value: selectedClient,
      itemHeight: 65,
      onItemSelected: (item) {
        setState(() {
          selectedClient = item;
        });
        widget.onClientSelected?.call(item);
      },
      itemBuilder: (item) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          child: UserPanelView(
            displayName: item.self!.displayName,
            detail: item.self!.detail,
            avatar: item.self!.avatar,
          ),
        );
      },
    );
  }
}
