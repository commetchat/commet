import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomPanel extends StatefulWidget {
  const RoomPanel(
      {required this.displayName,
      this.avatar,
      this.topic,
      this.onJoinButtonPressed,
      this.showJoinButton = false,
      super.key});
  final ImageProvider? avatar;
  final String displayName;
  final String? topic;
  final bool showJoinButton;
  final Function()? onJoinButtonPressed;
  @override
  State<RoomPanel> createState() => _RoomPanelState();
}

class _RoomPanelState extends State<RoomPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Avatar.medium(
                  image: widget.avatar,
                  placeholderText: widget.displayName,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: tiamat.Text.labelEmphasised(widget.displayName),
                ),
                SizedBox(
                  width: 20,
                  child: Seperator(),
                ),
                if (widget.topic != null) tiamat.Text.body(widget.topic!),
              ],
            ),
            if (widget.showJoinButton)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                child: Button.success(
                  text: "Join",
                  onTap: () {
                    widget.onJoinButtonPressed?.call();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
