import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@WidgetbookUseCase(name: 'No Avatar', type: UserPanel)
@Deprecated("widgetbook")
Widget wbUserPanelDefault(BuildContext context) {
  return const Center(child: UserPanel(displayName: "User"));
}

@WidgetbookUseCase(name: 'With Avatar', type: UserPanel)
@Deprecated("widgetbook")
Widget wbUserPanelWithAvatar(BuildContext context) {
  return const Center(
      child: UserPanel(
    displayName: "User",
    avatar: AssetImage("assets/images/placeholder/generic/checker_purple.png"),
  ));
}

class UserPanel extends StatefulWidget {
  const UserPanel(
      {super.key,
      this.avatar,
      required this.displayName,
      this.color,
      this.detail,
      this.onClicked});
  final ImageProvider? avatar;
  final String displayName;
  final Color? color;
  final String? detail;
  final void Function()? onClicked;

  @override
  State<UserPanel> createState() => _UserPanelState();
}

class _UserPanelState extends State<UserPanel> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: material.Material(
        color: material.Colors.transparent,
        child: material.InkWell(
          splashColor: material.Theme.of(context).highlightColor,
          onTap: widget.onClicked,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
            child: Row(
              children: [
                Avatar.medium(
                  image: widget.avatar,
                  placeholderText: widget.displayName,
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tiamat.Text.name(
                          widget.displayName,
                          color: widget.color,
                        ),
                        if (widget.detail != null)
                          tiamat.Text.tiny(widget.detail!),
                      ],
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
