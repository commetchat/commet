import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/invitation/invitation.dart';
import 'package:commet/client/components/invitation/invitation_component.dart';
import 'package:commet/ui/molecules/invitation_display.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class SingleInvitationComponentIncomingView extends StatefulWidget {
  const SingleInvitationComponentIncomingView(this.component,
      {super.key, this.showCurrentUserId = false});
  final InvitationComponent component;
  final bool showCurrentUserId;

  @override
  State<SingleInvitationComponentIncomingView> createState() =>
      _SingleInvitationComponentIncomingViewState();
}

class _SingleInvitationComponentIncomingViewState
    extends State<SingleInvitationComponentIncomingView> {
  String labelInvitationsForUser(String user) => Intl.message(
      "Invitations for $user",
      desc:
          "Label for the list of incoming invitations, specifying which user these invitations are intended for",
      args: [user],
      name: "labelInvitationsForUser");

  String get labelInvitations => Intl.message("Invitations",
      desc: "Label for the list of incoming invitations",
      name: "labelInvitations");

  StreamSubscription? sub;

  @override
  void initState() {
    sub = widget.component.invitations.onListUpdated.listen((event) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.component.invitations.isEmpty) return Container();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: tiamat.Panel(
          mode: tiamat.TileType.surfaceContainer,
          header: widget.showCurrentUserId
              ? labelInvitationsForUser(
                  widget.component.client.self!.displayName)
              : labelInvitations,
          child: Column(
            children: [
              for (var invite in widget.component.invitations)
                InvitationDisplay(
                  invite,
                  acceptInvitation: (invitation) =>
                      acceptInvitation(widget.component, invitation),
                  rejectInvitation: (invitation) =>
                      rejectInvitation(widget.component, invitation),
                )
            ],
          )),
    );
  }

  Future<void> acceptInvitation(
      InvitationComponent<Client> comp, Invitation invite) async {
    await comp.acceptInvitation(invite);
  }

  Future<void> rejectInvitation(
      InvitationComponent<Client> comp, Invitation invite) async {
    await comp.rejectInvitation(invite);
  }
}
