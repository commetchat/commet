import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/pages/matrix/verification/matrix_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';
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
        state: KeyVerificationState.askSas,
        sasTypes: ['emoji'],
        sasEmoji: [
          KeyVerificationEmoji(1),
          KeyVerificationEmoji(2),
          KeyVerificationEmoji(3),
          KeyVerificationEmoji(4),
          KeyVerificationEmoji(5),
          KeyVerificationEmoji(6),
        ],
        sasNumbers: [1, 2, 3, 4, 5, 6],
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
        state: KeyVerificationState.askAccept,
        sasTypes: ['emoji'],
        sasEmoji: [
          KeyVerificationEmoji(1),
          KeyVerificationEmoji(2),
          KeyVerificationEmoji(3),
          KeyVerificationEmoji(4),
          KeyVerificationEmoji(5),
          KeyVerificationEmoji(6),
        ],
        sasNumbers: [1, 2, 3, 4, 5, 6],
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

  final KeyVerificationState state;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300, maxWidth: 300),
        child: AspectRatio(aspectRatio: 1, child: determineStage(context)));
  }

  Widget determineStage(BuildContext context) {
    switch (state) {
      case KeyVerificationState.askAccept:
        return promptAcceptRequest(context);
      case KeyVerificationState.askSas:
        return promptAskSas(context);
      case KeyVerificationState.done:
        return done(context);
      default:
        return tiamat.Text.label(state.toString());
    }
  }

  Widget promptAcceptRequest(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Button(
          text: T.current.genericAcceptButton,
          onTap: onVerificationRequestAccepted?.call,
        ),
        Button.danger(
          text: T.current.genericRejectButton,
          onTap: onVerificationRequestRejected?.call,
        )
      ],
    );
  }

  Widget promptAskSas(BuildContext context) {
    if (sasTypes.contains('emoji')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: sasEmoji.map((e) => tiamat.Text.largeTitle(e.emoji)).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Button(
                  text: T.current.sasEmojiVerificationMatches,
                  onTap: onSasAccepted?.call,
                ),
                Button.danger(
                  text: T.current.sasEmojiVerificationDoesntMatch,
                  onTap: onSasRejected?.call,
                )
              ],
            )
          ],
        ),
      );
    }
    return Placeholder();
  }

  Widget done(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Button.success(
        text: T.current.sasVerificationDone,
      )
    ]);
  }
}
