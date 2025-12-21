import 'dart:math';

import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class RandomEmojiButton extends StatefulWidget {
  const RandomEmojiButton(
      {this.size = 20, this.toggled = false, this.onTap, super.key});
  final double size;
  final Function()? onTap;
  final bool toggled;

  @override
  State<RandomEmojiButton> createState() => _RandomEmojiButtonState();
}

class _RandomEmojiButtonState extends State<RandomEmojiButton> {
  String emoji = "🙂";
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme.secondary;

    var hsl = HSLColor.fromColor(color);
    double lightness = hsl.lightness;
    if (Theme.of(context).brightness == Brightness.light) {
      lightness = ui.clampDouble(hsl.lightness, 0.7, 1);
    }

    color =
        HSLColor.fromAHSL(1.0, hsl.hue, hsl.saturation, lightness).toColor();

    bool showColor = hovered || widget.toggled;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onHover: (isHovered) {
            setState(() {
              hovered = isHovered;
              if (!hovered) {
                newRandomEmoji();
              }
            });
          },
          onTap: () {
            if (Layout.mobile) {
              setState(() {
                newRandomEmoji();
              });
            }

            widget.onTap?.call();
          },
          child: Center(
            child: AnimatedScale(
              scale: showColor ? 1.2 : 1,
              curve: Curves.easeOutCubic,
              duration: Duration(milliseconds: 100),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                    color, showColor ? BlendMode.dst : (BlendMode.modulate)),
                child: ColorFiltered(
                  colorFilter: contrast(showColor ? 0 : 0.3),
                  child: ColorFiltered(
                    colorFilter: saturationColorFilter(showColor ? 1 : 0),
                    child: EmojiWidget(
                      UnicodeEmoticon(emoji),
                      padding: EdgeInsetsGeometry.all(1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void newRandomEmoji() {
    var options =
        "😍🥺🥰😊😵‍💫😵🤩😎😘😅🤓😁😆🤣😂🙂😉😊😚😙😋😛😜🤪😝🤑🤠🥳🥸🥶😈"
            .characters
            .toList();
    var r = Random();
    emoji = options[r.nextInt(options.length)];
  }

  ColorFilter saturationColorFilter(double saturation) {
    const double r = 0.2126;
    const double g = 0.7152;
    const double b = 0.0722;

    final double invSat = 1 - saturation;

    return ColorFilter.matrix(<double>[
      ...[invSat * r + saturation, invSat * g, invSat * b, 0, 0],
      ...[invSat * r, invSat * g + saturation, invSat * b, 0, 0],
      ...[invSat * r, invSat * g, invSat * b + saturation, 0, 0],
      ...[0, 0, 0, 1, 0],
    ]);
  }

  ColorFilter invertColors() {
    return ColorFilter.matrix([
      ...[-1, 0, 0, 0, 255],
      ...[0, -1, 0, 0, 255],
      ...[0, 0, -1, 0, 255],
      ...[0, 0, 0, 1, 0],
    ]);
  }

  ColorFilter invertAlpha() {
    return ColorFilter.matrix([
      ...[1, 0, 0, 0, 0],
      ...[0, 1, 0, 0, 0],
      ...[0, 0, 1, 0, 0],
      ...[0, 0, 0, -1, 255],
    ]);
  }

  contrast(double value) {
    double adj = value * 255;
    double factor = (259 * (adj + 255)) / (255 * (259 - adj));
    return ColorFilter.matrix([
      ...[factor, 0, 0, 0, 128 * (1 - factor)],
      ...[0, factor, 0, 0, 128 * (1 - factor)],
      ...[0, 0, factor, 0, 128 * (1 - factor)],
      ...[0, 0, 0, 1, 0],
    ]);
  }
}
