import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'Default', type: Avatar)
Widget wbavatarDefault(BuildContext context) {
  return const Center(
      child: Avatar(
    image: AssetImage("assets/images/placeholder/generic/checker_purple.png"),
  ));
}

@UseCase(name: 'Large', type: Avatar)
Widget wbavatarLarge(BuildContext context) {
  return const Center(
      child: Avatar.large(
    image: AssetImage("assets/images/placeholder/generic/checker_purple.png"),
  ));
}

@UseCase(name: 'Placeholder', type: Avatar)
Widget wbavatarPlaceholder(BuildContext context) {
  return const Center(
      child: Avatar(
    placeholderText: "A",
  ));
}

@UseCase(name: 'Placeholder Large', type: Avatar)
Widget wbavatarPlaceholderLarge(BuildContext context) {
  return const Center(
      child: Avatar.large(
    placeholderText: "A",
  ));
}

class Avatar extends StatelessWidget {
  const Avatar(
      {Key? key,
      this.image,
      this.radius = 22,
      this.placeholderText,
      this.placeholderColor,
      this.isPadding = false})
      : super(key: key);

  const Avatar.small({
    Key? key,
    this.image,
    this.placeholderText,
    this.placeholderColor,
    this.isPadding = false,
  })  : radius = 15,
        super(key: key);

  const Avatar.medium(
      {Key? key,
      required this.image,
      this.placeholderText,
      this.placeholderColor,
      this.isPadding = false})
      : radius = 22,
        super(key: key);

  const Avatar.large(
      {Key? key,
      this.image,
      this.placeholderText,
      this.placeholderColor,
      this.isPadding = false})
      : radius = 44,
        super(key: key);

  const Avatar.extraLarge(
      {Key? key,
      this.image,
      this.placeholderText,
      this.placeholderColor,
      this.isPadding = false})
      : radius = 80,
        super(key: key);

  final double radius;
  final ImageProvider? image;
  final String? placeholderText;
  final Color? placeholderColor;
  final bool isPadding;

  @override
  Widget build(BuildContext context) {
    if (isPadding) {
      return SizedBox(
        width: radius * 2,
        height: 1,
      );
    }

    if (image != null) {
      return SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: DecoratedBox(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius / 1.25),
                image: DecorationImage(
                    image: image!,
                    isAntiAlias: true,
                    filterQuality: FilterQuality.medium,
                    fit: BoxFit.cover))),
      );
    }

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: placeholderText != null
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius / 1.25),
                color: placeholderColor ?? Colors.transparent,
              ),
              child: Align(
                  alignment: Alignment.center,
                  child: placeholderText != null
                      ? Text(
                          placeholderText!.substring(0, 1).toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(fontSize: radius),
                        )
                      : null),
            )
          : null,
    );
  }
}
