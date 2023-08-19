import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:flutter/material.dart' as m;
import './text.dart' as tiamat;

@WidgetbookUseCase(name: 'Default', type: ImageButton)
Widget wbimageButton(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: const [
              SizedBox(
                width: 128,
                height: 128,
                child: ImageButton(
                  size: 128,
                  image: AssetImage(
                      "assets/images/placeholder/generic/checker_purple.png"),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: tiamat.Text.body("128px"),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: const [
              SizedBox(
                width: 64,
                height: 64,
                child: ImageButton(
                  size: 64,
                  image: AssetImage(
                      "assets/images/placeholder/generic/checker_purple.png"),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: tiamat.Text.body("64px"),
              )
            ],
          ),
        ),
      ],
    ),
  );
}

@WidgetbookUseCase(name: 'Icon', type: ImageButton)
Widget wbimageButtonIcon(BuildContext context) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  SizedBox(
                    width: 128,
                    height: 128,
                    child: ImageButton(
                      size: 128,
                      icon: m.Icons.settings,
                    ),
                  ),
                  SizedBox(
                    width: 128,
                    height: 128,
                    child: ImageButton(
                      size: 128,
                      icon: m.Icons.home,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: tiamat.Text.body("128px"),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: const [
              SizedBox(
                width: 64,
                height: 64,
                child: ImageButton(
                  size: 64,
                  icon: m.Icons.settings,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: tiamat.Text.body("64px"),
              )
            ],
          ),
        ),
      ],
    ),
  );
}

@WidgetbookUseCase(name: 'Icon with Shadow', type: ImageButton)
Widget wbimageButtonIconWithShadow(BuildContext context) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  SizedBox(
                    width: 128,
                    height: 128,
                    child: ImageButton(
                      size: 128,
                      icon: m.Icons.settings,
                      doShadow: true,
                    ),
                  ),
                  SizedBox(
                    width: 128,
                    height: 128,
                    child: ImageButton(
                      size: 128,
                      icon: m.Icons.home,
                      doShadow: true,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: tiamat.Text.body("128px"),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: const [
              SizedBox(
                width: 64,
                height: 64,
                child: ImageButton(
                  size: 64,
                  icon: m.Icons.settings,
                  doShadow: true,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
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
  const ImageButton(
      {super.key,
      this.onTap,
      this.image,
      this.doShadow = false,
      this.iconSize,
      required this.size,
      this.icon});
  final void Function()? onTap;
  final ImageProvider? image;
  final double size;
  final double? iconSize;
  final IconData? icon;
  final bool doShadow;

  @override
  State<ImageButton> createState() => _ImageButtonState();
}

class _ImageButtonState extends State<ImageButton> {
  double _borderRadius = 0;
  double hoverRadius = 5;
  double unhoverRadius = 3.4;

  @override
  void initState() {
    _borderRadius = widget.size / unhoverRadius;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (event) {
            setState(() {
              _borderRadius = widget.size / hoverRadius;
            });
          },
          onExit: (event) {
            setState(() {
              _borderRadius = widget.size / unhoverRadius;
            });
          },
          child: createImageContainer(context)),
    );
  }

  Widget createImageContainer(BuildContext context) {
    return TweenAnimationBuilder<BorderRadius>(
      tween: Tween(
          begin: BorderRadius.circular(_borderRadius),
          end: BorderRadius.circular(_borderRadius)),
      builder: (context, value, child) {
        return Container(
          decoration: widget.doShadow
              ? BoxDecoration(borderRadius: value, boxShadow: [
                  BoxShadow(
                      color: Theme.of(context).colorScheme.shadow,
                      blurRadius: 10)
                ])
              : widget.image == null
                  ? BoxDecoration(
                      borderRadius: value.add(BorderRadius.circular(2)),
                      border: Border.all(
                          color: Theme.of(context)
                              .extension<ExtraColors>()!
                              .outline,
                          width: 1),
                    )
                  : null,
          child: ClipRRect(
            borderRadius: value,
            child: Material(
              child: child,
            ),
          ),
        );
      },
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: createInkwell(),
    );
  }

  InkWell createInkwell() {
    return InkWell(
      onTap: widget.onTap,
      child: widget.image != null
          ? Ink(
              child: Image(
                filterQuality: FilterQuality.medium,
                image: widget.image!,
                fit: BoxFit.cover,
              ),
            )
          : widget.icon != null
              ? Icon(
                  widget.icon,
                  size: widget.iconSize ?? widget.size / 2.5,
                )
              : null,
    );
  }
}
