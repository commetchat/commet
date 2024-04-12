import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MiniCallMenuIncoming extends StatelessWidget {
  const MiniCallMenuIncoming(
      {required this.roomDisplayName,
      required this.callingUserName,
      this.isRoomDirectMessage = false,
      this.onAccept,
      this.onDecline,
      super.key});
  final String roomDisplayName;
  final String callingUserName;
  final bool isRoomDirectMessage;
  final Function()? onAccept;
  final Function()? onDecline;

  String get incomingCallMessage =>
      Intl.message("Incoming call from $callingUserName!",
          desc: "Label to display that a user is calling",
          args: [callingUserName],
          name: "incomingCallMessage");

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          tiamat.Text.labelEmphasised(incomingCallMessage),
          if (isRoomDirectMessage == false)
            tiamat.Text.labelLow(roomDisplayName),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              tiamat.Button(
                text: CommonStrings.promptAccept,
                onTap: onAccept,
              ),
              const SizedBox(
                width: 10,
              ),
              tiamat.Button.secondary(
                text: CommonStrings.promptDecline,
                onTap: onDecline,
              )
            ],
          )
        ]);
  }
}
