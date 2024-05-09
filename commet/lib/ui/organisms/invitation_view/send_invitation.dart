import 'package:commet/client/client.dart';
import 'package:commet/client/components/invitation/invitation_component.dart';
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
  List<Peer>? searchResultUserIds;

  bool get showRecommendations =>
      !(isSearching || searchResultUserIds?.isNotEmpty == true);

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

    return SafeArea(
      child: SizedBox(
          width: 500,
          child: Column(children: [
            tiamat.TextInput(
              controller: controller,
              icon: const Icon(Icons.search),
              maxLines: 1,
              onChanged: onSearchTextChanged,
            ),
            if (isSearching || searchResultUserIds != null)
              SizedBox(
                  height: 300,
                  child: isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: searchResultUserIds!.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return UserPanel(
                              searchResultUserIds![index],
                              showFullId: true,
                              onTap: () =>
                                  invitePeer(searchResultUserIds![index]),
                            );
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
                      var peer =
                          room.client.getPeer(room.directMessagePartnerID!);
                      return UserPanel(
                        peer,
                        showFullId: true,
                        onTap: () => invitePeer(peer),
                      );
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
      searchResultUserIds = null;
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
      searchResultUserIds = result;
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
