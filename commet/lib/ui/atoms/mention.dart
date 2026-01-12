import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MentionWidget extends StatelessWidget {
  const MentionWidget(
      {required this.displayName,
      required this.placeholderColor,
      this.avatar,
      this.style,
      this.fallbackIcon,
      this.onTap,
      super.key});
  final String displayName;
  final ImageProvider? avatar;
  final Function()? onTap;
  final IconData? fallbackIcon;
  final TextStyle? style;
  final Color placeholderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Theme.of(context).colorScheme.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fallbackIcon != null && avatar == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 1, 0),
                    child: Icon(
                      fallbackIcon,
                      size: 14,
                      color: tiamat.Text.adjustColor(context, placeholderColor),
                    ),
                  ),
                if (avatar != null || fallbackIcon == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 3, 0),
                    child: tiamat.Avatar(
                      placeholderText: displayName,
                      placeholderColor: placeholderColor,
                      image: avatar,
                      radius: 8,
                    ),
                  ),
                Text(displayName,
                    textScaler: TextScaler.noScaling,
                    style: (style ?? Theme.of(context).textTheme.bodyMedium)
                        ?.copyWith(
                            fontVariations: [FontVariation.weight(400)],
                            color: tiamat.Text.adjustColor(
                                context, placeholderColor))),
              ],
            ),
          ),
        ));
  }
}
