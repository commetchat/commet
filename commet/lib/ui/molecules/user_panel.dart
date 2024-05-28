import 'package:commet/client/client.dart';
import 'package:commet/client/member.dart';
import 'package:commet/ui/atoms/shimmer_loading.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/user_profile/user_profile.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'No Avatar', type: UserPanelView)
@Deprecated("widgetbook")
Widget wbUserPanelDefault(BuildContext context) {
  return const Center(child: UserPanelView(displayName: "User"));
}

@UseCase(name: 'With Avatar', type: UserPanelView)
@Deprecated("widgetbook")
Widget wbUserPanelWithAvatar(BuildContext context) {
  return const Center(
      child: UserPanelView(
    displayName: "User",
    avatar: AssetImage("assets/images/placeholder/generic/checker_purple.png"),
  ));
}

class MemberPanel extends material.StatefulWidget {
  const MemberPanel(this.peer,
      {super.key, this.userColor, this.showFullId = false, this.onTap});
  final Member peer;
  final Color? userColor;
  final bool showFullId;
  final void Function()? onTap;

  @override
  State<MemberPanel> createState() => _MemberPanelState();
}

class _MemberPanelState extends material.State<MemberPanel> {
  @override
  material.Widget build(material.BuildContext context) {
    return UserPanelView(
      displayName: widget.peer.displayName,
      avatar: widget.peer.avatar,
      detail: widget.showFullId ? widget.peer.identifier : widget.peer.detail,
      color: widget.userColor,
      avatarColor: widget.userColor,
      nameColor: widget.userColor,
      onClicked: widget.onTap ?? onUserPanelClicked,
    );
  }

  void onUserPanelClicked() {
    // TODO: Update user profile display

    // AdaptiveDialog.show(context,
    //     builder: (_) => UserProfile(
    //           user: widget.peer,
    //           dismiss: () => Navigator.pop(context),
    //         ),
    //     title: "User");
  }
}

class UserPanelView extends material.StatelessWidget {
  const UserPanelView(
      {super.key,
      this.avatar,
      required this.displayName,
      this.color,
      this.avatarColor,
      this.nameColor,
      this.detail,
      this.padding,
      this.shimmer = false,
      this.random = 0,
      this.onClicked});
  final ImageProvider? avatar;
  final String displayName;
  final Color? color;
  final Color? avatarColor;
  final Color? nameColor;
  final String? detail;
  final EdgeInsets? padding;
  final bool shimmer;
  final double random;
  final void Function()? onClicked;

  @override
  Widget build(BuildContext context) {
    var shimmerColor = Theme.of(context).extension<ExtraColors>()!.highlight;

    var widget = ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: material.Material(
        color: material.Colors.transparent,
        child: material.InkWell(
          splashColor: material.Theme.of(context).highlightColor,
          onTap: onClicked,
          child: Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Avatar.small(
                  image: shimmer ? null : avatar,
                  placeholderText: shimmer ? " " : displayName,
                  placeholderColor: shimmer ? shimmerColor : avatarColor,
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: material.MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (shimmer)
                            Container(
                              height: 10,
                              width: (random * 50) + 50,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: shimmerColor),
                            ),
                          if (shimmer)
                            material.Padding(
                              padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                              child: Container(
                                height: 8,
                                width: (random * 20) + 20,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: shimmerColor),
                              ),
                            ),
                          if (!shimmer)
                            tiamat.Text.name(
                              displayName,
                              color: nameColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (detail != null) tiamat.Text.tiny(detail!),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );

    if (shimmer) {
      return ShimmerLoading(isLoading: true, child: widget);
    }

    return widget;
  }
}
