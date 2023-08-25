import 'package:commet/client/client.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/user_profile/user_profile.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@WidgetbookUseCase(name: 'No Avatar', type: UserPanelView)
@Deprecated("widgetbook")
Widget wbUserPanelDefault(BuildContext context) {
  return const Center(child: UserPanelView(displayName: "User"));
}

@WidgetbookUseCase(name: 'With Avatar', type: UserPanelView)
@Deprecated("widgetbook")
Widget wbUserPanelWithAvatar(BuildContext context) {
  return const Center(
      child: UserPanelView(
    displayName: "User",
    avatar: AssetImage("assets/images/placeholder/generic/checker_purple.png"),
  ));
}

class UserPanel extends material.StatefulWidget {
  const UserPanel(this.peer, {super.key, this.userColor});
  final Peer peer;
  final Color? userColor;

  @override
  State<UserPanel> createState() => _UserPanelState();
}

class _UserPanelState extends material.State<UserPanel> {
  @override
  void initState() {
    widget.peer.loading?.then((value) {
      if (mounted) setState(() {});
    });

    super.initState();
  }

  @override
  material.Widget build(material.BuildContext context) {
    return UserPanelView(
      displayName: widget.peer.displayName,
      avatar: widget.peer.avatar,
      detail: widget.peer.detail,
      color: widget.userColor,
      avatarColor: widget.userColor,
      nameColor: widget.userColor,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      onClicked: onUserPanelClicked,
    );
  }

  void onUserPanelClicked() {
    AdaptiveDialog.show(context,
        builder: (_) => UserProfile(
              user: widget.peer,
              dismiss: () => Navigator.pop(context),
            ),
        title: "User");
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
      this.onClicked});
  final ImageProvider? avatar;
  final String displayName;
  final Color? color;
  final Color? avatarColor;
  final Color? nameColor;
  final String? detail;
  final EdgeInsets? padding;
  final void Function()? onClicked;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
                  image: avatar,
                  placeholderText: displayName,
                  placeholderColor: avatarColor,
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
  }
}
