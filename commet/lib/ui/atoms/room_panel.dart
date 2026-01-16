import 'package:commet/ui/atoms/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomPanel extends StatefulWidget {
  const RoomPanel(
      {required this.displayName,
      this.avatar,
      this.onPrimaryButtonPressed,
      this.primaryButtonLabel,
      this.onSecondaryButtonPressed,
      this.secondaryButtonLabel,
      this.userColor,
      this.onTap,
      this.color,
      this.body,
      this.recentEventSender,
      this.recentEventSenderColor,
      this.userAvatar,
      this.loading = false,
      this.random = 1,
      this.userDisplayName,
      this.showUserAvatar = false,
      super.key});
  final ImageProvider? avatar;
  final ImageProvider? userAvatar;
  final Color? userColor;
  final String? userDisplayName;
  final String displayName;
  final Color? color;
  final String? body;
  final String? recentEventSender;
  final Color? recentEventSenderColor;
  final String? primaryButtonLabel;
  final Future<void> Function()? onPrimaryButtonPressed;
  final Function()? onTap;
  final String? secondaryButtonLabel;
  final Future<void> Function()? onSecondaryButtonPressed;
  final bool showUserAvatar;
  final bool loading;
  final double random;
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

  bool get showOnlyPrimaryButton => showPrimaryButton && !showSecondaryButton;

  bool get showAnyButton => showPrimaryButton || showSecondaryButton;

  bool primaryButtonLoading = false;
  bool secondaryButtonLoading = false;

  @override
  Widget build(BuildContext context) {
    var shimmerColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    bool shimmer = widget.loading;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Shimmer(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Container(
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(15)),
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
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  ShimmerLoading(
                                    isLoading: widget.loading,
                                    child: Avatar.medium(
                                      image: widget.avatar,
                                      placeholderText:
                                          shimmer ? " " : widget.displayName,
                                      placeholderColor:
                                          shimmer ? shimmerColor : widget.color,
                                    ),
                                  ),
                                  if (widget.showUserAvatar)
                                    Avatar(
                                      radius: 10,
                                      image: widget.userAvatar,
                                      placeholderText: widget.userDisplayName,
                                      placeholderColor: widget.userColor,
                                    ),
                                ],
                              ),
                              Flexible(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (shimmer)
                                        ShimmerLoading(
                                          isLoading: shimmer,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 4, 0, 0),
                                            child: Container(
                                              height: 16,
                                              width: (widget.random * 80) + 20,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  color: shimmerColor),
                                            ),
                                          ),
                                        ),
                                      if (shimmer)
                                        ShimmerLoading(
                                          isLoading: shimmer,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 4, 0, 0),
                                            child: Container(
                                              height: 12,
                                              width: (widget.random * 200) + 20,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  color: shimmerColor),
                                            ),
                                          ),
                                        ),
                                      if (!shimmer)
                                        tiamat.Text.labelEmphasised(
                                          widget.displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (widget.body != null &&
                                          widget.recentEventSenderColor !=
                                              null &&
                                          widget.recentEventSender != null)
                                        Flexible(child: recentEvent())
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showAnyButton) actionButtons(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget recentEvent() {
    var color =
        tiamat.Text.adjustColor(context, widget.recentEventSenderColor!);

    var style = TextTheme.of(context)
        .labelMedium
        ?.copyWith(fontSize: 12, letterSpacing: 0);
    return SizedBox(
      height: 30,
      child: RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(children: [
            TextSpan(
              text: widget.recentEventSender! + ":",
              style: style?.copyWith(color: color),
            ),
            WidgetSpan(
                child: SizedBox(
              width: 4,
            )),
            TextSpan(
                text: widget.body,
                style:
                    style?.copyWith(color: ColorScheme.of(context).secondary))
          ])),
    );
  }

  Widget actionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showPrimaryButton)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
            child: Button(
              text: widget.primaryButtonLabel!,
              isLoading: primaryButtonLoading,
              onTap: () async {
                setState(() {
                  primaryButtonLoading = true;
                });
                await widget.onPrimaryButtonPressed?.call();

                if (mounted) {
                  setState(() {
                    primaryButtonLoading = false;
                  });
                }
              },
            ),
          ),
        if (showSecondaryButton)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
            child: Button.secondary(
              text: widget.secondaryButtonLabel!,
              isLoading: secondaryButtonLoading,
              onTap: () async {
                setState(() {
                  secondaryButtonLoading = true;
                });

                await widget.onSecondaryButtonPressed?.call();
                if (mounted) {
                  setState(() {
                    secondaryButtonLoading = false;
                  });
                }
              },
            ),
          ),
      ],
    );
  }
}
