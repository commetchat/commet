import 'package:commet/client/client.dart';
import 'package:commet/client/components/invitation/invitation_component.dart';
import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/ui/pages/settings/categories/app/boolean_toggle.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class ChatPrivacyPreferences<T extends Client> extends StatefulWidget {
  const ChatPrivacyPreferences({required this.client, super.key});
  final T client;

  @override
  State<ChatPrivacyPreferences> createState() => _ChatPrivacyPreferences();
}

class _ChatPrivacyPreferences extends State<ChatPrivacyPreferences> {
  UserPresenceComponent get userPresenceComponent =>
      widget.client.getComponent<UserPresenceComponent>()!;

  InvitationComponent get invitationsComponent =>
      widget.client.getComponent<InvitationComponent>()!;

  String get labelChatPrivacyTitle => Intl.message("Chat Privacy",
      desc: "Header for the chat privacy section in settings",
      name: "labelChatPrivacyTitle");

  String get labelPublicReadReceiptsToggle => Intl.message("Read receipts",
      desc:
          "Label for the toggle for enabling and disabling sending read receipts",
      name: "labelPublicReadReceiptsToggle");

  String get labelPublicReadReceiptsDescription => Intl.message(
      "Let other members of a room know when you have read their messages.",
      desc:
          "description for the toggle for enabling and disabling sending read receipts",
      name: "labelPublicReadReceiptsDescription");

  String get labelTypingIndicatorsToggle => Intl.message("Typing indicator",
      desc:
          "Label for the toggle for enabling and disabling sending typing indicator",
      name: "labelTypingIndicatorsToggle");

  String get labelPublicTypingIndicatorDescription => Intl.message(
      "Let other members of a room know when you are typing a message.",
      desc:
          "description for the toggle for enabling and disabling sending typing indicator",
      name: "labelPublicTypingIndicatorDescription");

  String get labelAllowInvitationsToggle => Intl.message("Allow invitations",
      desc:
          "Label for the toggle for enabling and disabling the automatic blocking of invitations",
      name: "labelAllowInvitationsToggle");

  String get labelAllowInvitationsDescription => Intl.message(
      "Allow other users to invite you to rooms",
      desc:
          "description for the toggle for enabling and disabling the automatic blocking of invitations",
      name: "labelAllowInvitationsDescription");

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return tiamat.Panel(
      header: labelChatPrivacyTitle,
      mode: tiamat.TileType.surfaceContainerLow,
      child: Column(children: [
        BooleanToggle(
          setValue: (value) async {
            await ErrorUtils.tryRun(context, () async {
              await userPresenceComponent.setUsePublicReadReceipts(value);
            });
          },
          getValue: () => userPresenceComponent.usePublicReadReceipts,
          title: labelPublicReadReceiptsToggle,
          description: labelPublicReadReceiptsDescription,
        ),
        BooleanToggle(
          setValue: (value) async {
            await ErrorUtils.tryRun(context, () async {
              await userPresenceComponent.setTypingIndicatorEnabled(value);
            });
          },
          getValue: () => userPresenceComponent.typingIndicatorEnabled,
          title: labelPublicReadReceiptsToggle,
          description: labelPublicReadReceiptsDescription,
        ),
        BooleanToggle(
          setValue: (value) async {
            await ErrorUtils.tryRun(context, () async {
              await invitationsComponent.setInvitationsAllowed(value);
            });
          },
          getValue: () => invitationsComponent.allowInvitations,
          title: labelAllowInvitationsToggle,
          description: labelAllowInvitationsDescription,
        ),
      ]),
    );
  }
}
