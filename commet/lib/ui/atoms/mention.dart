import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MentionWidget extends StatelessWidget {
  const MentionWidget(
      {required this.displayName,
      required this.placeholderColor,
      this.avatar,
      this.onTap,
      super.key});
  final String displayName;
  final ImageProvider? avatar;
  final Function()? onTap;
  final Color placeholderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Theme.of(context).colorScheme.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                tiamat.Avatar(
                  placeholderText: displayName,
                  placeholderColor: placeholderColor,
                  image: avatar,
                  radius: 8,
                ),
                SizedBox(
                  width: 3,
                ),
                tiamat.Text(
                  displayName,
                  color: placeholderColor,
                  autoAdjustBrightness: true,
                ),
              ],
            ),
          ),
        ));
  }
}
