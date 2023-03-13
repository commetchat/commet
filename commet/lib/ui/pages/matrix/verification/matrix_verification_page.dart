import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixVerificationPage extends StatefulWidget {
  const MatrixVerificationPage({required this.request, required this.client, super.key});
  final KeyVerification request;
  final Client client;
  @override
  State<MatrixVerificationPage> createState() => _MatrixVerificationPageState();
}

class _MatrixVerificationPageState extends State<MatrixVerificationPage> {
  void Function()? originalOnUpdate;
  late final List<dynamic> sasEmoji;

  @override
  void initState() {
    originalOnUpdate = widget.request.onUpdate;
    widget.request.onUpdate = () {
      originalOnUpdate?.call();
      setState(() {});
    };

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.request.state) {
      case KeyVerificationState.askAccept:
        return promptAcceptRequest();
      case KeyVerificationState.askSas:
        return promptAskSas();

      case KeyVerificationState.done:
        return done();
      default:
        return tiamat.Text.label(widget.request.state.toString());
    }
  }

  Widget promptAcceptRequest() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Button(
          text: "Accept",
          onTap: acceptRequest,
        ),
        Button.danger(
          text: "Reject",
          onTap: rejectRequest,
        )
      ],
    );
  }

  Widget promptAskSas() {
    if (widget.request.sasTypes.contains('emoji')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.request.sasEmojis.map((e) => tiamat.Text.largeTitle(e.emoji)).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Button(
                  text: "They Match",
                  onTap: acceptSas,
                ),
                Button.danger(
                  text: "They Don't Match",
                  onTap: rejectSas,
                )
              ],
            )
          ],
        ),
      );
    }
    return Placeholder();
  }

  Widget done() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Button.success(
        text: "Done!",
      )
    ]);
  }

  void acceptRequest() async {
    await widget.request.acceptVerification();
  }

  void rejectRequest() async {
    await widget.request.acceptVerification();
  }

  void acceptSas() async {
    widget.request.acceptSas();
  }

  void rejectSas() async {
    widget.request.rejectSas();
  }
}
