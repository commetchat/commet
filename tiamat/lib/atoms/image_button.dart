import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:flutter/material.dart' as m;
import './text.dart' as tiamat;

@UseCase(name: 'Default', type: ImageButton)
Widget wbimageButton(BuildContext context) {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
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
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
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

@UseCase(name: 'Icon', type: ImageButton)
Widget wbimageButtonIcon(BuildContext context) {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
              Padding(
                padding: EdgeInsets.all(8.0),
                child: tiamat.Text.body("128px"),
              )
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
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

@UseCase(name: 'Icon with Shadow', type: ImageButton)
Widget wbimageButtonIconWithShadow(BuildContext context) {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
              Padding(
                padding: EdgeInsets.all(8.0),
                child: tiamat.Text.body("128px"),
              )
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
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

@UseCase(name: 'Placeholder', type: ImageButton)
Widget wbImageButtonPlaceholder(BuildContext context) {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 128,
                    height: 128,
                    child: ImageButton(
                      size: 128,
                      placeholderColor: Colors.amberAccent,
                      placeholderText: "Abcdefg",
                    ),
                  ),
                  SizedBox(
                    width: 128,
                    height: 128,
                    child: ImageButton(
                      size: 128,
                      placeholderColor: Colors.amberAccent,
                      placeholderText: "Abcdefg",
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: tiamat.Text.body("128px"),
              )
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: ImageButton(
                  size: 64,
                  placeholderColor: Colors.amberAccent,
                  placeholderText: "Abcdefg",
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
      this.placeholderColor,
      this.placeholderText,
      this.boxBorder,
      required this.size,
      this.icon});
  final void Function()? onTap;
  final ImageProvider? image;
  final double size;
  final double? iconSize;
  final String? placeholderText;
  final Color? placeholderColor;
  final BoxBorder? boxBorder;
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
          clipBehavior: Clip.antiAlias,
          foregroundDecoration: BoxDecoration(
              border: widget.boxBorder ??
                  (widget.image == null
                      ? Border.all(
                          color: Theme.of(context)
                              .extension<ExtraColors>()!
                              .outline,
                          strokeAlign: BorderSide.strokeAlignCenter,
                          width: 2)
                      : null),
              borderRadius: value),
          decoration: widget.doShadow
              ? BoxDecoration(
                  borderRadius: value,
                  border: widget.boxBorder,
                  boxShadow: [
                      BoxShadow(
                          color: Theme.of(context).colorScheme.shadow,
                          blurRadius: 10)
                    ])
              : widget.image == null
                  ? BoxDecoration(
                      color: widget.placeholderColor,
                      borderRadius: value,
                    )
                  : BoxDecoration(borderRadius: value),
          child: Material(
            color: widget.image == null ? widget.placeholderColor : null,
            child: child,
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
                : widget.placeholderText != null
                    ? Container(
                        child: Align(
                            alignment: Alignment.center,
                            child: widget.placeholderText != null
                                ? Text(
                                    widget.placeholderText!
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall!
                                        .copyWith(fontSize: widget.size / 4),
                                  )
                                : null))
                    : null);
  }
}
