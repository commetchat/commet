import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:matrix/encryption/utils/key_verification.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class MatrixVerificationPageView extends StatelessWidget {
  const MatrixVerificationPageView(
      {required this.state,
      required this.sasTypes,
      required this.sasNumbers,
      required this.sasEmoji,
      required this.userID,
      super.key,
      this.onVerificationRequestAccepted,
      this.onVerificationRequestRejected,
      this.onSasAccepted,
      this.onSasRejected});

  final Function? onVerificationRequestAccepted;
  final Function? onVerificationRequestRejected;
  final Function? onSasAccepted;
  final Function? onSasRejected;
  final List<String> sasTypes;
  final List<KeyVerificationEmoji> sasEmoji;
  final List<int> sasNumbers;
  final String userID;

  final KeyVerificationState state;

  String get messageWaitingOtherDeviceToAccept => Intl.message(
      "Waiting for the other device to accept the request",
      name: "messageWaitingOtherDeviceToAccept",
      desc:
          "Message to show while waiting for another device to accept a matrix session verification request");

  String messageMatrixSessionVerificationRequest(String username) => Intl.message(
      "**$username** has requested to verify your session",
      desc:
          "Message to show when another user has requested to verify your matrix session. Supports markdown to emphasise the user name",
      args: [username],
      name: "messageMatrixSessionVerificationRequest");

  String get messageSasEmojiVerificationPrompt => Intl.message(
      "Check that the emoji are the same, and in the same order as on the other device",
      name: "messageSasEmojiVerificationPrompt",
      desc:
          "Explains what to look for when verifying using emoji. Needs to portray that the emoji MUST be the same AND in the same order");

  String get promptConfirmEmojiMatches => Intl.message("They match!",
      name: "promptConfirmEmojiMatches",
      desc: "Button text to confirm that the emoji matches");

  String get promptEmojiDoNotMatch => Intl.message("They don't match",
      name: "promptEmojiDoNotMatch",
      desc: "Button text to confirm that the emoji do NOT match");

  String get messageVerificationComplete => Intl.message(
      "Verification Complete!",
      name: "messageVerificationComplete",
      desc:
          "Message to show when verification was completed successfully, and the session has been verified");

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 350, width: 500, child: determineStage(context));
  }

  Widget determineStage(BuildContext context) {
    switch (state) {
      case KeyVerificationState.askAccept:
        return promptAcceptRequest(context);
      case KeyVerificationState.askSas:
        return promptAskSas(context);
      case KeyVerificationState.done:
        return done(context);
      case KeyVerificationState.waitingAccept:
        return Column(
          children: [
            tiamat.Text.label(messageWaitingOtherDeviceToAccept),
            loading(context)
          ],
        );
      case KeyVerificationState.waitingSas:
        return loading(context);
      default:
        return tiamat.Text.label(state.toString());
    }
  }

  Widget promptAcceptRequest(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Markdown(
                data: messageMatrixSessionVerificationRequest(userID))),
        Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Button.success(
                  text: CommonStrings.promptAccept,
                  onTap: onVerificationRequestAccepted?.call),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Button.danger(
                text: CommonStrings.promptReject,
                onTap: onVerificationRequestRejected?.call,
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget promptAskSas(BuildContext context) {
    if (sasTypes.contains('emoji')) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: tiamat.Text.label(messageSasEmojiVerificationPrompt),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Wrap(
              spacing: 15,
              runSpacing: 5,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: sasEmoji
                  .map((e) => Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            EmojiWidget(
                              UnicodeEmoticon(e.emoji),
                              height: 30,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: tiamat.Text.tiny(e.name),
                            )
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Button.success(
                      text: promptConfirmEmojiMatches,
                      onTap: onSasAccepted?.call),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Button.danger(
                    text: promptEmojiDoNotMatch,
                    onTap: onSasRejected?.call,
                  ),
                )
              ],
            ),
          )
        ],
      );
    }
    return const Placeholder();
  }

  Widget done(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
              child: Center(
                  child: Icon(
            Icons.verified_user_rounded,
            color: Colors.green,
            size: 100,
          ))),
          Button.success(
            text: messageVerificationComplete,
            onTap: () => Navigator.pop(context),
          )
        ]);
  }

  Widget loading(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
