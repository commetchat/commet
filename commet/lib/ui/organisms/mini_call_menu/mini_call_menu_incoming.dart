import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MiniCallMenuIncoming extends StatelessWidget {
  const MiniCallMenuIncoming(
      {required this.roomDisplayName,
      this.onAccept,
      this.onDecline,
      super.key});
  final String roomDisplayName;
  final Function()? onAccept;
  final Function()? onDecline;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          tiamat.Text.labelEmphasised("Incoming call!"),
          tiamat.Text.label(roomDisplayName),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              tiamat.Button(
                text: "Accept",
                onTap: onAccept,
              ),
              SizedBox(
                width: 10,
              ),
              tiamat.Button.secondary(
                text: "Decline",
                onTap: onDecline,
              )
            ],
          )
        ]);
  }
}
