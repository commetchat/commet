import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../config/build_config.dart';

class RoomPanel extends StatefulWidget {
  const RoomPanel(
      {required this.displayName,
      this.avatar,
      this.topic,
      this.onPrimaryButtonPressed,
      this.primaryButtonLabel,
      this.primaryButtonLoading = false,
      this.onSecondaryButtonPressed,
      this.secondaryButtonLabel,
      this.secondaryButtonLoading = false,
      this.onRoomSettingsButtonPressed,
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
  final bool showSettingsButton;
  final Color? color;
  final String? recentEventBody;
  final String? recentEventSender;
  final Color? recentEventSenderColor;
  final String? primaryButtonLabel;
  final bool primaryButtonLoading;
  final Function()? onPrimaryButtonPressed;
  final Function()? onRoomSettingsButtonPressed;
  final Function()? onTap;
  final String? secondaryButtonLabel;
  final bool secondaryButtonLoading;
  final Function()? onSecondaryButtonPressed;
  @override
  State<RoomPanel> createState() => _RoomPanelState();
}

class _RoomPanelState extends State<RoomPanel> {
  bool get showPrimaryButton =>
      widget.primaryButtonLabel != null &&
      widget.onPrimaryButtonPressed != null;

  bool get showSecondaryButton =>
      widget.secondaryButtonLabel != null &&
      widget.onSecondaryButtonPressed != null;

  bool get showOnlyPrimaryButton =>
      showPrimaryButton &&
      !showSecondaryButton &&
      widget.showSettingsButton != true;

  bool get showAnyButton => showPrimaryButton || showSecondaryButton;

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
              child: Column(
                children: [
                  Row(
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
                                      recentEvent()
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (BuildConfig.DESKTOP || showOnlyPrimaryButton)
                        Flexible(
                            child: actionButtons(widget.showSettingsButton)),
                      if (BuildConfig.MOBILE && widget.showSettingsButton)
                        settingsButton(),
                    ],
                  ),
                  if (BuildConfig.MOBILE && !showOnlyPrimaryButton)
                    actionButtons(false)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget recentEvent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      mainAxisSize: MainAxisSize.min,
      textBaseline: TextBaseline.alphabetic,
      children: [
        tiamat.Text(
          widget.recentEventSender!,
          type: TextType.labelLow,
          autoAdjustBrightness: true,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          color: widget.recentEventSenderColor,
        ),
        tiamat.Text.labelLow(
          widget.recentEventBody!,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        )
      ],
    );
  }

  Widget actionButtons(bool includeSettings) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showPrimaryButton)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
              child: Button(
                text: widget.primaryButtonLabel!,
                isLoading: widget.primaryButtonLoading,
                onTap: () {
                  widget.onPrimaryButtonPressed?.call();
                },
              ),
            ),
          ),
        if (showSecondaryButton)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
              child: Button.secondary(
                text: widget.secondaryButtonLabel!,
                isLoading: widget.secondaryButtonLoading,
                onTap: () {
                  widget.onSecondaryButtonPressed?.call();
                },
              ),
            ),
          ),
        if (includeSettings) settingsButton(),
      ],
    );
  }

  Widget settingsButton() {
    return tiamat.CircleButton(
      icon: Icons.settings,
      radius: BuildConfig.MOBILE ? 24 : 16,
      onPressed: widget.onRoomSettingsButtonPressed,
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
