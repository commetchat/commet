import 'dart:ui';

import 'package:commet/config/style/theme_extensions.dart';
import 'package:commet/ui/atoms/shader_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class Background extends StatelessWidget {
  const Background(this.color,
      {this.child, this.width, this.decoration, super.key, this.sigma = 0, this.opacity = 1, this.frosted = false});
  final Color color;
  final Widget? child;
  final double? width;
  final Decoration? decoration;
  final bool frosted;
  final double sigma;
  final double? opacity;
  static FragmentShader? shader;
  static bool shaderLoading = false;

  Background.high(BuildContext context, {this.child, this.width, this.decoration, this.opacity, Key? key})
      : color = Theme.of(context).extension<ExtraColors>()!.surfaceHigh1,
        frosted = Theme.of(context).extension<ThemeSettings>()!.frosted,
        this.sigma = 0,
        super(key: key);

  Background.surface(BuildContext context, {this.child, this.width, this.decoration, Key? key})
      : color = Theme.of(context).colorScheme.surface,
        frosted = Theme.of(context).extension<ThemeSettings>()!.frosted,
        sigma = 3,
        opacity = 0.7,
        super(key: key);

  Background.low1(BuildContext context, {this.child, this.width, this.decoration, Key? key})
      : color = Theme.of(context).extension<ExtraColors>()!.surfaceLow1,
        frosted = Theme.of(context).extension<ThemeSettings>()!.frosted,
        sigma = 10,
        opacity = 0.9,
        super(key: key);

  Background.low2(BuildContext context, {this.child, this.width, this.decoration, Key? key})
      : color = Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
        frosted = Theme.of(context).extension<ThemeSettings>()!.frosted,
        sigma = 15,
        opacity = 0.9,
        super(key: key);

  Background.low3(BuildContext context, {this.child, this.width, this.decoration, Key? key})
      : color = Theme.of(context).extension<ExtraColors>()!.surfaceLow3,
        frosted = Theme.of(context).extension<ThemeSettings>()!.frosted,
        opacity = 0.9,
        sigma = 20,
        super(key: key);

  Background.lowest(BuildContext context, {this.child, this.width, this.decoration, Key? key})
      : color = Theme.of(context).extension<ExtraColors>()!.surfaceLowest,
        frosted = Theme.of(context).extension<ThemeSettings>()!.frosted,
        sigma = 30,
        opacity = 0.95,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (frosted)
      return Stack(
        children: [
          ClipRect(
              child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: ShaderBackground())),
          Container(color: opacity != null ? color.withAlpha((opacity! * 255.0).toInt()) : color, child: child!),
        ],
      );

    return Container(
      color: decoration == null ? color : null,
      width: width,
      decoration: decoration,
      child: Container(
        child: child,
      ),
    );
  }
}
