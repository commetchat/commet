import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

class Foundation extends StatelessWidget {
  const Foundation({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    var data = Theme.of(context).extension<FoundationSettings>();

    var texture = data?.getTexture();

    return Container(
      color: data?.settings.color,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (texture != null)
            Image(
              image: texture.image,
              fit: BoxFit.cover,
              //fit: data.imageFit,
            ),
          Padding(
            padding: data?.settings.padding ?? EdgeInsets.zero,
            child: child,
          ),
        ],
      ),
    );
  }
}
