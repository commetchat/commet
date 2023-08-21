import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../config/build_config.dart';

class RoomPanel extends StatefulWidget {
  const RoomPanel(
      {required this.displayName,
      this.avatar,
      this.topic,
      this.onJoinButtonPressed,
      this.onRoomSettingsButtonPressed,
      this.showJoinButton = false,
      this.showSettingsButton = false,
      this.onTap,
      this.color,
      super.key});
  final ImageProvider? avatar;
  final String displayName;
  final String? topic;
  final bool showJoinButton;
  final bool showSettingsButton;
  final Color? color;
  final Function()? onJoinButtonPressed;
  final Function()? onRoomSettingsButtonPressed;
  final Function()? onTap;
  @override
  State<RoomPanel> createState() => _RoomPanelState();
}

class _RoomPanelState extends State<RoomPanel> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
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
                        placeholderColor: widget.color,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: tiamat.Text.labelEmphasised(widget.displayName),
                      ),
                      const SizedBox(
                        width: 20,
                        child: Seperator(),
                      ),
                      if (widget.topic != null) tiamat.Text.body(widget.topic!),
                    ],
                  ),
                  Row(
                    children: [
                      if (widget.showJoinButton)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                          child: Button(
                            text: "Join",
                            onTap: () {
                              widget.onJoinButtonPressed?.call();
                            },
                          ),
                        ),
                      if (widget.showSettingsButton)
                        tiamat.CircleButton(
                          icon: Icons.settings,
                          radius: BuildConfig.MOBILE ? 24 : 16,
                          onPressed: widget.onRoomSettingsButtonPressed,
                        )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
