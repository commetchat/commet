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
      this.recentEventBody,
      this.recentEventSender,
      this.recentEventSenderColor,
      super.key});
  final ImageProvider? avatar;
  final String displayName;
  final String? topic;
  final bool showJoinButton;
  final bool showSettingsButton;
  final Color? color;
  final String? recentEventBody;
  final String? recentEventSender;
  final Color? recentEventSenderColor;
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
                children: [
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Avatar.medium(
                          image: widget.avatar,
                          placeholderText: widget.displayName,
                          placeholderColor: widget.color,
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                nameAndTopic(),
                                if (widget.recentEventBody != null &&
                                    widget.recentEventSender != null)
                                  Flexible(child: recentEvent())
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actionButtons()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget recentEvent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      mainAxisSize: MainAxisSize.min,
      textBaseline: TextBaseline.alphabetic,
      children: [
        tiamat.Text(
          widget.recentEventSender!,
          type: TextType.labelLow,
          autoAdjustBrightness: true,
          color: widget.recentEventSenderColor,
        ),
        const SizedBox(
          width: 10,
        ),
        Flexible(
          child: tiamat.Text.labelLow(
            widget.recentEventBody!,
            overflow: TextOverflow.fade,
          ),
        )
      ],
    );
  }

  Widget actionButtons() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
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
    );
  }

  Widget nameAndTopic() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        tiamat.Text.labelEmphasised(widget.displayName),
        if (widget.topic != null)
          const SizedBox(
            width: 20,
            child: Seperator(),
          ),
        if (widget.topic != null) tiamat.Text.body(widget.topic!),
      ],
    );
  }
}
