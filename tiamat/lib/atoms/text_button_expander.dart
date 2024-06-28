import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'Default', type: TextButtonExpander)
Widget wbTextButtonExpander(BuildContext context) {
  return Center(
      child: SizedBox(
    height: 1000,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const material.Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(
            height: 50,
            child: tiamat.TextButton(
              "Test",
              icon: Icons.tag,
            ),
          ),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: TextButtonExpander(
            "Test 2",
            icon: Icons.format_list_bulleted_sharp,
            children: ["Test", "test", "Test"]
                .map((e) => SizedBox(
                      height: 40,
                      child: tiamat.TextButton(
                        e,
                        icon: Icons.tag,
                      ),
                    ))
                .toList(),
          ),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: TextButtonExpander(
            "Test 2",
            icon: Icons.format_list_bulleted_sharp,
            avatarPlaceholderColor: Colors.amber.shade800,
            avatarPlaceholderText: "A",
            children: ["Test 1", "Test 2", "Test 3"]
                .map((e) => TextButtonExpander(
                      e,
                      initiallyExpanded: true,
                      icon: Icons.format_list_bulleted_sharp,
                      children: ["Test", "test", "Test"]
                          .map((e) => SizedBox(
                                height: 40,
                                child: tiamat.TextButton(
                                  e,
                                  icon: Icons.tag,
                                ),
                              ))
                          .toList(),
                    ))
                .toList(),
          ),
        ),
      ],
    ),
  ));
}

class TextButtonExpander extends StatelessWidget {
  const TextButtonExpander(
    this.text, {
    super.key,
    this.children = const <Widget>[],
    this.icon,
    this.highlighted = false,
    this.textColor,
    this.iconColor,
    this.avatar,
    this.iconSize = 20,
    this.avatarRadius = 12,
    this.initiallyExpanded = false,
    this.avatarPlaceholderColor,
    this.avatarPlaceholderText,
    this.enabled = true,
    this.childrenPadding = const EdgeInsets.fromLTRB(8, 0, 0, 0),
    this.textPadding = const EdgeInsets.fromLTRB(8, 0, 0, 0),
  });

  final List<Widget> children;

  final IconData? icon;
  final ImageProvider? avatar;
  final String? avatarPlaceholderText;
  final Color? avatarPlaceholderColor;
  final bool highlighted;
  final double iconSize;
  final double avatarRadius;
  final Color? textColor;
  final Color? iconColor;
  final String text;
  final bool initiallyExpanded;
  final bool enabled;

  final EdgeInsetsGeometry childrenPadding;
  final EdgeInsetsGeometry textPadding;
  bool get useAvatar => avatar != null || avatarPlaceholderText != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        material.ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          visualDensity: material.VisualDensity.compact,
          dense: true,
          enabled: enabled,
          children: children,
          childrenPadding: childrenPadding,
          title:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null || useAvatar)
                  Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: avatarRadius * 2,
                        height: avatarRadius * 2,
                        child: useAvatar
                            ? tiamat.Avatar(
                                radius: avatarRadius,
                                image: avatar,
                                placeholderColor: avatarPlaceholderColor,
                                placeholderText: avatarPlaceholderText,
                              )
                            : Icon(
                                size: iconSize,
                                icon!,
                                weight: 0.5,
                                color: highlighted
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer
                                    : iconColor ??
                                        Theme.of(context).colorScheme.onSurface,
                              ),
                      ),
                    ),
                  ),
                Padding(
                  padding: textPadding,
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: tiamat.Text.labelEmphasised(
                        text,
                        color: highlighted
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : textColor,
                      )),
                ),
              ],
            ),
          ]),
        )
      ],
    );
  }
}
