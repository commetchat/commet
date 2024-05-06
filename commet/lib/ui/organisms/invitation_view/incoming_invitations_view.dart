import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/invitation/invitation_component.dart';
import 'package:commet/ui/organisms/invitation_view/single_invitation_component_view.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

class IncomingInvitationsWidget extends StatefulWidget {
  const IncomingInvitationsWidget(this.manager, {super.key});

  final ClientManager manager;

  @override
  State<IncomingInvitationsWidget> createState() =>
      _IncomingInvitationsWidgetState();
}

class _IncomingInvitationsWidgetState extends State<IncomingInvitationsWidget> {
  @override
  Widget build(BuildContext context) {
    var components = widget.manager.clients
        .map((element) => element.getComponent<InvitationComponent>())
        .whereNotNull();

    if (components.isEmpty) {
      return Container();
    }

    return Column(
      children: [
        for (var comp in components)
          if (comp.invitations.isNotEmpty)
            SingleInvitationComponentIncomingView(
              comp,
              showCurrentUserId: widget.manager.clients.length > 1,
            )
      ],
    );
  }
}
