import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import './text.dart' as tiamat;

import '../../config/app_config.dart';
import '../../config/style/theme_extensions.dart';
import 'circle_button.dart';

@WidgetbookUseCase(name: 'Default', type: ImageButton)
Widget wb_imageButton(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                width: 128,
                height: 128,
                child: ImageButton(
                  size: 128,
                  image: AssetImage("assets/images/placeholder/generic/checker_purple.png"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: tiamat.Text.body("128px"),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: ImageButton(
                  size: 64,
                  image: AssetImage("assets/images/placeholder/generic/checker_purple.png"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: tiamat.Text.body("64px"),
              )
            ],
          ),
        ),
      ],
    ),
  );
}

class ImageButton extends StatefulWidget {
  ImageButton({super.key, this.onTap, this.image, required this.size, this.icon});
  void Function()? onTap;
  ImageProvider? image;
  double size;
  IconData? icon;

  @override
  State<ImageButton> createState() => _ImageButtonState();
}

class _ImageButtonState extends State<ImageButton> {
  double _borderRadius = 0;

  @override
  void initState() {
    _borderRadius = widget.size / 2.5;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (event) {
            setState(() {
              _borderRadius = widget.size / 5;
            });
          },
          onExit: (event) {
            setState(() {
              _borderRadius = widget.size / 2.5;
            });
          },
          child: createImageContainer(context)),
    );
  }

  Widget createImageContainer(BuildContext context) {
    return TweenAnimationBuilder<BorderRadius>(
      tween: Tween(begin: BorderRadius.circular(_borderRadius), end: BorderRadius.circular(_borderRadius)),
      builder: (context, value, child) {
        return ClipRRect(
          borderRadius: value,
          child: Material(
            child: child,
          ),
        );
      },
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: widget.image != null
          ? Ink.image(image: widget.image!, fit: BoxFit.cover, child: createInkwell())
          : createInkwell(),
    );
  }

  InkWell createInkwell() {
    return InkWell(onTap: () {
      widget.onTap?.call();
    });
  }
}
