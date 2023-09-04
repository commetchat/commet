import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class UserProfileView extends StatefulWidget {
  const UserProfileView(
      {super.key,
      this.userAvatar,
      required this.displayName,
      required this.userColor,
      required this.identifier,
      required this.isSelf,
      this.onMessageButtonClicked});
  final ImageProvider? userAvatar;
  final String displayName;
  final String identifier;
  final Color userColor;
  final bool isSelf;

  final Future<void> Function()? onMessageButtonClicked;

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  bool isLoadingDirectMessage = false;

  String get promptOpenDirectMessage => Intl.message("Message",
      desc: "Prompt on the button to open a direct message with another user",
      name: "promptOpenDirectMessage");

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [userAvatarAndName(), if (!widget.isSelf) actionButtons()],
    );
  }

  Widget userAvatarAndName() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
          child: tiamat.Avatar.large(
            image: widget.userAvatar,
            placeholderText: widget.displayName,
            placeholderColor: widget.userColor,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tiamat.Text.largeTitle(widget.displayName),
            tiamat.Text.tiny(widget.identifier)
          ],
        ),
      ],
    );
  }

  Widget actionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        tiamat.Button(
          text: promptOpenDirectMessage,
          onTap: clickMessageButton,
          isLoading: isLoadingDirectMessage,
        ),
      ],
    );
  }

  Future<void> clickMessageButton() async {
    setState(() {
      isLoadingDirectMessage = true;
    });

    await widget.onMessageButtonClicked?.call();

    setState(() {
      isLoadingDirectMessage = false;
    });
  }
}
