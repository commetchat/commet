import 'package:commet/client/client.dart';
import 'package:commet/client/components/invitation/invitation_component.dart';
import 'package:commet/client/profile.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/debounce.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class SendInvitationWidget extends StatefulWidget {
  const SendInvitationWidget(this.room, this.component, {super.key});
  final Room room;
  final InvitationComponent component;

  @override
  State<SendInvitationWidget> createState() => _SendInvitationWidgetState();
}

class _SendInvitationWidgetState extends State<SendInvitationWidget> {
  late TextEditingController controller;
  late Debouncer debouncer;

  bool isSearching = false;
  List<Profile>? searchResults;

  bool get showRecommendations =>
      !(isSearching || searchResults?.isNotEmpty == true);

  @override
  void initState() {
    controller = TextEditingController();
    debouncer = Debouncer(delay: const Duration(milliseconds: 500));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var recommended = widget.room.client.directMessages;

    recommended.removeWhere(
      (element) =>
          widget.room.memberIds.contains(element.directMessagePartnerID),
    );

    return ScaledSafeArea(
      child: SizedBox(
          width: 500,
          child: Column(children: [
            tiamat.TextInput(
              controller: controller,
              icon: const Icon(Icons.search),
              maxLines: 1,
              onChanged: onSearchTextChanged,
            ),
            if (isSearching || searchResults != null)
              SizedBox(
                  height: 300,
                  child: isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: searchResults!.length,
                          shrinkWrap: true,
                          // TODO: Mini profile view
                          itemBuilder: (context, index) {
                            return tiamat.Text(
                                searchResults![index].identifier);
                          },
                        )),
            if (showRecommendations && recommended.isNotEmpty)
              Column(
                children: [
                  const tiamat.Seperator(),
                  const tiamat.Text.labelLow("Recommended"),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: recommended.length,
                    itemBuilder: (context, index) {
                      var room = recommended[index];
                      // TODO: Mini Profile View
                      return tiamat.Text(room.directMessagePartnerID!);
                    },
                  ),
                ],
              )
          ])),
    );
  }

  void onSearchTextChanged(String value) async {
    setState(() {
      isSearching = value.isNotEmpty;
      searchResults = null;
      debouncer.cancel();
    });

    if (value.isNotEmpty) {
      debouncer.run(() => doSearch(value));
    }
  }

  void doSearch(String value) async {
    var result = await widget.component.searchUsers(value);

    setState(() {
      isSearching = false;
      searchResults = result;
    });
  }

  void invitePeer(Peer peer) async {
    final confirm = await AdaptiveDialog.confirmation(context,
        prompt:
            "Are you sure you want to Invite ${peer.identifier} to the room ${widget.room.displayName}?",
        title: "Invitation");
    if (confirm != true) {
      return;
    }

    widget.component.inviteUserToRoom(
        userId: peer.identifier, roomId: widget.room.identifier);

    if (mounted) Navigator.pop(context);
  }
}
