import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../config/build_config.dart';

class RoomPanel extends StatefulWidget {
  const RoomPanel(
      {required this.displayName,
      this.avatar,
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
      this.body,
      this.recentEventSender,
      this.recentEventSenderColor,
      super.key});
  final ImageProvider? avatar;
  final String displayName;
  final bool showSettingsButton;
  final Color? color;
  final String? body;
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

  bool get showAnyButton =>
      showPrimaryButton || showSecondaryButton || widget.showSettingsButton;

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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
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
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    tiamat.Text.labelEmphasised(
                                      widget.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (widget.body != null)
                                      Flexible(child: recentEvent())
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showAnyButton)
                        actionButtons(widget.showSettingsButton),
                    ],
                  ),
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
        if (widget.recentEventSender != null)
          tiamat.Text(
            widget.recentEventSender!,
            type: TextType.labelLow,
            autoAdjustBrightness: true,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            color: widget.recentEventSenderColor,
          ),
        tiamat.Text.labelLow(
          widget.body!,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        )
      ],
    );
  }

  Widget actionButtons(bool includeSettings) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showPrimaryButton)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
            child: Button(
              text: widget.primaryButtonLabel!,
              isLoading: widget.primaryButtonLoading,
              onTap: () {
                widget.onPrimaryButtonPressed?.call();
              },
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
}
