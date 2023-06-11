import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:matrix/encryption/utils/key_verification.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@WidgetbookUseCase(name: 'Check Emojis', type: MatrixVerificationPageView)
@Deprecated("widgetbook")
Widget wbSASCheckEmojis(BuildContext context) {
  return Scaffold(
    body: PopupDialog(
      title: "Verification Request",
      content: MatrixVerificationPageView(
        userID: "alice@example.com",
        state: KeyVerificationState.askSas,
        sasTypes: const ['emoji'],
        sasEmoji: [
          KeyVerificationEmoji(25),
          KeyVerificationEmoji(41),
          KeyVerificationEmoji(61),
          KeyVerificationEmoji(53),
          KeyVerificationEmoji(49),
          KeyVerificationEmoji(4),
        ],
        sasNumbers: const [25, 41, 61, 53, 49, 4],
      ),
    ),
  );
}

@WidgetbookUseCase(name: 'Loading', type: MatrixVerificationPageView)
@Deprecated("widgetbook")
Widget sbVerificationLoading(BuildContext context) {
  return Scaffold(
    body: PopupDialog(
      title: "Verification Request",
      content: MatrixVerificationPageView(
        userID: "alice@example.com",
        state: KeyVerificationState.waitingAccept,
        sasTypes: const ['emoji'],
        sasEmoji: [
          KeyVerificationEmoji(25),
          KeyVerificationEmoji(41),
          KeyVerificationEmoji(61),
          KeyVerificationEmoji(53),
          KeyVerificationEmoji(49),
          KeyVerificationEmoji(4),
        ],
        sasNumbers: const [25, 41, 61, 53, 49, 4],
      ),
    ),
  );
}

@WidgetbookUseCase(name: 'Request Received', type: MatrixVerificationPageView)
@Deprecated("widgetbook")
Widget wbSASRequestReceived(BuildContext context) {
  return Scaffold(
    body: PopupDialog(
      title: "Verification Request",
      content: MatrixVerificationPageView(
        userID: "alice@example.com",
        state: KeyVerificationState.askAccept,
        sasTypes: const ['emoji'],
        sasEmoji: [
          KeyVerificationEmoji(25),
          KeyVerificationEmoji(41),
          KeyVerificationEmoji(61),
          KeyVerificationEmoji(53),
          KeyVerificationEmoji(49),
          KeyVerificationEmoji(4),
        ],
        sasNumbers: const [25, 41, 61, 53, 49, 4],
      ),
    ),
  );
}

@WidgetbookUseCase(name: 'Done', type: MatrixVerificationPageView)
@Deprecated("widgetbook")
Widget wbVerificationSuccess(BuildContext context) {
  return Scaffold(
    body: PopupDialog(
      title: "Verification Request",
      content: MatrixVerificationPageView(
        userID: "alice@example.com",
        state: KeyVerificationState.done,
        sasTypes: const ['emoji'],
        sasEmoji: [
          KeyVerificationEmoji(25),
          KeyVerificationEmoji(41),
          KeyVerificationEmoji(61),
          KeyVerificationEmoji(53),
          KeyVerificationEmoji(49),
          KeyVerificationEmoji(4),
        ],
        sasNumbers: const [25, 41, 61, 53, 49, 4],
      ),
    ),
  );
}

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
            const tiamat.Text.label(
                "Waiting for other device to accept request"),
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
            child: Markdown(data: T.current.verificationRequestPrompt(userID))),
        Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Button.success(
                  text: T.current.genericAcceptButton,
                  onTap: onVerificationRequestAccepted?.call),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Button.danger(
                text: T.current.genericRejectButton,
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
              child: tiamat.Text.label(T.current.sasEmojiVerificationPrompt),
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
                      text: T.current.sasEmojiVerificationMatches,
                      onTap: onSasAccepted?.call),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Button.danger(
                    text: T.current.sasEmojiVerificationDoesntMatch,
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
            text: T.current.sasVerificationDone,
            onTap: () => Navigator.pop(context),
          )
        ]);
  }

  Widget loading(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
