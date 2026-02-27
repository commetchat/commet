import 'package:commet/client/client.dart';
import 'package:commet/client/components/user_presence/user_presence_component.dart';
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
  bool publicReadReceipts = true;
  bool publicTypingIndicator = true;

  UserPresenceComponent get userPresenceComponent =>
      widget.client.getComponent<UserPresenceComponent>()!;

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
      name: "labelPublicReadReceiptsDescriptionn");

  String get labelTypingIndicatorsToggle => Intl.message("Typing indicator",
      desc:
          "Label for the toggle for enabling and disabling sending typing indicator",
      name: "labelTypingIndicatorsToggle");

  String get labelPublicTypingIndicatorDescription => Intl.message(
      "Let other members of a room know when you are typing a message.",
      desc:
          "description for the toggle for enabling and disabling sending typing indicator",
      name: "labelPublicTypingIndicatorDescription");

  @override
  void initState() {
    setState(() {
      publicReadReceipts = userPresenceComponent.usePublicReadReceipts;
      publicTypingIndicator = userPresenceComponent.typingIndicatorEnabled;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return tiamat.Panel(
      header: labelChatPrivacyTitle,
      mode: tiamat.TileType.surfaceContainerLow,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tiamat.Text.labelEmphasised(
                          labelPublicReadReceiptsToggle),
                      tiamat.Text.labelLow(labelPublicReadReceiptsDescription)
                    ]),
              ),
              tiamat.Switch(
                  state: publicReadReceipts,
                  onChanged: (value) async {
                    setState(() {
                      publicReadReceipts = value;
                    });
                    print(widget.client.getAllComponents());
                    await ErrorUtils.tryRun(context, () async {
                      await userPresenceComponent
                          .setUsePublicReadReceipts(value);
                    });
                    setState(() => publicReadReceipts = value);
                  })
            ],
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tiamat.Text.labelEmphasised(labelTypingIndicatorsToggle),
                      tiamat.Text.labelLow(
                          labelPublicTypingIndicatorDescription)
                    ]),
              ),
              tiamat.Switch(
                  state: publicTypingIndicator,
                  onChanged: (value) async {
                    setState(() {
                      publicTypingIndicator = value;
                    });
                    await ErrorUtils.tryRun(context, () async {
                      await userPresenceComponent
                          .setTypingIndicatorEnabled(value);
                    });
                    setState(() => publicTypingIndicator = value);
                  })
            ],
          ),
        ),
      ]),
    );
  }
}
