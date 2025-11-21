import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import './text.dart' as tiamat;

@UseCase(name: 'Default', type: TextButton)
Widget wbiconUseCase(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 30,
            child: TextButton("Height: 30", icon: Icons.tag),
          ),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 35,
            child: TextButton("Height: 35", icon: Icons.tag),
          ),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 40,
            child: TextButton("Height: 40", icon: Icons.tag),
          ),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 45,
            child: TextButton("Height: 45", icon: Icons.tag),
          ),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 50,
            child: TextButton("Height: 50", icon: Icons.tag),
          ),
        ),
      ],
    ),
  );
}

@UseCase(name: 'With Image', type: TextButton)
Widget wbiconUseCaseWithImage(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 30,
            child: TextButton(
              "Height: 30",
              avatar: AssetImage(
                "assets/images/placeholder/generic/checker_purple.png",
              ),
              icon: Icons.tag,
            ),
          ),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 35,
            child: TextButton(
              "Height: 35",
              avatar: AssetImage(
                "assets/images/placeholder/generic/checker_purple.png",
              ),
              icon: Icons.tag,
            ),
          ),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 40,
            child: TextButton(
              "Height: 40",
              avatar: AssetImage(
                "assets/images/placeholder/generic/checker_purple.png",
              ),
              icon: Icons.tag,
            ),
          ),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 45,
            child: TextButton(
              "Height: 45",
              avatar: AssetImage(
                "assets/images/placeholder/generic/checker_purple.png",
              ),
              icon: Icons.tag,
            ),
          ),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 50,
            child: TextButton(
              "Height: 50",
              avatar: AssetImage(
                "assets/images/placeholder/generic/checker_purple.png",
              ),
              icon: Icons.tag,
            ),
          ),
        ),
      ],
    ),
  );
}

@UseCase(name: 'With Avatar Placeholder', type: TextButton)
Widget wbiconUseCaseWithAvatarPlaceholder(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 30,
            child: TextButton(
              "Height: 30",
              avatarPlaceholderText: "A",
              avatarPlaceholderColor: Colors.amber,
              icon: Icons.tag,
            ),
          ),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 35,
            child: TextButton(
              "Height: 35",
              avatarPlaceholderText: "A",
              avatarPlaceholderColor: Colors.amber,
              icon: Icons.tag,
            ),
          ),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 40,
            child: TextButton(
              "Height: 40",
              avatarPlaceholderText: "A",
              avatarPlaceholderColor: Colors.amber,
              icon: Icons.tag,
            ),
          ),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 45,
            child: TextButton(
              "Height: 45",
              avatarPlaceholderText: "A",
              avatarPlaceholderColor: Colors.amber,
              icon: Icons.tag,
            ),
          ),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
            height: 50,
            child: TextButton(
              "Height: 50",
              avatarPlaceholderText: "A",
              avatarPlaceholderColor: Colors.amber,
              icon: Icons.tag,
            ),
          ),
        ),
      ],
    ),
  );
}

class TextButton extends StatelessWidget {
  const TextButton(
    this.text, {
    super.key,
    this.icon,
    this.onTap,
    this.highlighted = false,
    this.textColor,
    this.iconColor,
    this.avatar,
    this.iconSize = 20,
    this.avatarRadius = 12,
    this.avatarPlaceholderColor,
    this.avatarPlaceholderText,
    this.customBuilder,
    this.softwrap,
    this.footer,
  });
  final String text;

  final IconData? icon;
  final ImageProvider? avatar;
  final String? avatarPlaceholderText;
  final Color? avatarPlaceholderColor;
  final bool highlighted;
  final double iconSize;
  final double avatarRadius;
  final void Function()? onTap;
  final Widget Function(Widget child, BuildContext context)? customBuilder;
  final Widget? footer;
  final Color? textColor;
  final Color? iconColor;
  final bool? softwrap;

  bool get useAvatar => avatar != null || avatarPlaceholderText != null;

  @override
  Widget build(BuildContext context) {
    Widget content = material.Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          ? Avatar(
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
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer
                                  : iconColor ??
                                        Theme.of(context).colorScheme.onSurface,
                            ),
                    ),
                  ),
                ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: tiamat.Text.labelEmphasised(
                      text,
                      maxLines: 1,
                      softwrap: softwrap,
                      overflow: TextOverflow.fade,
                      color: highlighted
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (footer != null) footer!,
      ],
    );

    if (customBuilder != null) {
      content = customBuilder!(content, context);
    }

    return material.TextButton(
      clipBehavior: Clip.antiAlias,
      style: ButtonStyle(
        padding: MaterialStatePropertyAll(
          material.EdgeInsets.fromLTRB(8, 0, 8, 0),
        ),
        backgroundColor: MaterialStatePropertyAll(
          highlighted ? Theme.of(context).colorScheme.secondaryContainer : null,
        ),
      ),
      child: content,
      onPressed: onTap,
    );
  }
}
