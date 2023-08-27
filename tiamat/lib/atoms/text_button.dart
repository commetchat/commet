import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
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
              height: 30, child: TextButton("Height: 30", icon: Icons.tag)),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
              height: 35, child: TextButton("Height: 35", icon: Icons.tag)),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
              height: 40, child: TextButton("Height: 40", icon: Icons.tag)),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
              height: 45, child: TextButton("Height: 45", icon: Icons.tag)),
        ),
        material.Padding(
          padding: EdgeInsets.all(8.0),
          child: material.SizedBox(
              height: 50, child: TextButton("Height: 50", icon: Icons.tag)),
        )
      ],
    ),
  );
}

class TextButton extends StatelessWidget {
  const TextButton(this.text,
      {super.key,
      this.icon,
      this.onTap,
      this.highlighted = false,
      this.textColor,
      this.iconColor,
      this.footer});
  final String text;

  final IconData? icon;
  final bool highlighted;
  final void Function()? onTap;
  final Widget? footer;
  final Color? textColor;
  final Color? iconColor;
  @override
  Widget build(BuildContext context) {
    return material.TextButton(
        clipBehavior: Clip.antiAlias,
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(
              highlighted ? Theme.of(context).highlightColor : null),
        ),
        child: material.Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null)
                    Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: Icon(
                          size: 20,
                          icon!,
                          weight: 0.5,
                          color: iconColor,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: tiamat.Text.labelEmphasised(
                          text,
                          color: textColor,
                        )),
                  ),
                ],
              ),
              if (footer != null) footer!,
            ]),
        onPressed: () => onTap?.call());
  }
}
