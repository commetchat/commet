import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/seperator.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

const String exampleText =
    "The quick brown fox jumped over the lazy dog 123 🤌👆️👎️🤓🫠😊😇😅😆";
const String loremIpsum =
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua";

@UseCase(name: 'Label', type: Text)
Widget wbtextLabelUseCase(BuildContext context) {
  return const material.Center(
    child: Text.label(exampleText),
  );
}

@UseCase(name: 'Tiny', type: Text)
Widget wbtextTinyUseCase(BuildContext context) {
  return const material.Center(
    child: Text.tiny(exampleText),
  );
}

@UseCase(name: 'Body', type: Text)
Widget wbtextBodyUseCase(BuildContext context) {
  return const material.Center(
    child: Text.body(exampleText),
  );
}

@UseCase(name: 'Error', type: Text)
Widget wbtextErrorUseCase(BuildContext context) {
  return const material.Center(
    child: Text.error(exampleText),
  );
}

@UseCase(name: 'Title', type: Text)
Widget wbtextTitleUseCase(BuildContext context) {
  return const material.Center(
    child: material.Padding(
      padding: EdgeInsets.all(8.0),
      child: Text.largeTitle(exampleText),
    ),
  );
}

@UseCase(name: 'Name', type: Text)
Widget wbtextNameUseCase(BuildContext context) {
  return const material.Center(
    child: material.Padding(
      padding: EdgeInsets.all(8.0),
      child: Text.name(
        exampleText,
        color: Colors.amber,
      ),
    ),
  );
}

@UseCase(name: 'All', type: Text)
Widget wbtextAllUseCase(BuildContext context) {
  return material.Padding(
    padding: const EdgeInsets.all(16.0),
    child: material.Center(
      child: material.Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text.largeTitle(exampleText),
          Seperator(),
          Align(
              alignment: Alignment.centerRight,
              child: Text.labelEmphasised(exampleText)),
          Align(
              alignment: Alignment.centerRight, child: Text.label(exampleText)),
          material.Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: Text.body(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."),
          ),
          material.Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: Text.tiny(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua"),
          ),
          Seperator(),
          Align(
              alignment: Alignment.centerRight, child: Text.error(exampleText)),
        ],
      ),
    ),
  );
}

enum TextType {
  label,
  labelEmphasised,
  labelLow,
  error,
  tiny,
  body,
  largeTitle,
  name
}

class Text extends StatelessWidget {
  const Text(this.text,
      {super.key,
      this.type = TextType.label,
      this.overflow,
      this.color,
      this.softwrap,
      this.autoAdjustBrightness,
      this.maxLines});
  final String text;
  final TextType type;
  final Color? color;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? autoAdjustBrightness;
  final bool? softwrap;

  const Text.label(
    this.text, {
    Key? key,
    this.overflow,
    this.maxLines,
    this.softwrap,
  })  : type = TextType.label,
        color = null,
        autoAdjustBrightness = false,
        super(key: key);

  const Text.labelEmphasised(
    this.text, {
    Key? key,
    this.overflow,
    this.color,
    this.maxLines,
    this.softwrap,
  })  : type = TextType.labelEmphasised,
        autoAdjustBrightness = false,
        super(key: key);

  const Text.error(
    this.text, {
    Key? key,
    this.overflow,
    this.maxLines,
    this.softwrap,
  })  : type = TextType.error,
        color = null,
        autoAdjustBrightness = false,
        super(key: key);

  const Text.tiny(
    this.text, {
    Key? key,
    this.overflow,
    this.maxLines,
    this.color,
    this.softwrap,
  })  : type = TextType.tiny,
        autoAdjustBrightness = false,
        super(key: key);

  const Text.body(
    this.text, {
    Key? key,
    this.overflow,
    this.maxLines,
    this.softwrap,
  })  : type = TextType.body,
        color = null,
        autoAdjustBrightness = false,
        super(key: key);

  const Text.largeTitle(
    this.text, {
    Key? key,
    this.overflow,
    this.maxLines,
    this.softwrap,
  })  : type = TextType.largeTitle,
        color = null,
        autoAdjustBrightness = false,
        super(key: key);

  const Text.name(
    this.text, {
    Key? key,
    this.color,
    this.overflow,
    this.maxLines,
    this.softwrap,
  })  : type = TextType.name,
        autoAdjustBrightness = true,
        super(key: key);

  const Text.labelLow(
    this.text, {
    Key? key,
    this.color,
    this.overflow,
    this.maxLines,
    this.softwrap,
  })  : type = TextType.labelLow,
        autoAdjustBrightness = false,
        super(key: key);

  static Color adjustColor(BuildContext context, Color color) {
    var hsl = HSLColor.fromColor(color!);
    double lightness = hsl.lightness;
    double saturation = hsl.saturation;
    if (Theme.of(context).brightness == Brightness.dark) {
      lightness = clampDouble(hsl.lightness, 0.75, 1);
    } else {
      lightness = clampDouble(hsl.lightness, 0, 0.7);
    }

    return HSLColor.fromAHSL(hsl.alpha, hsl.hue, saturation, lightness)
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style;
    var newColor = color;
    if (autoAdjustBrightness == true && color != null) {
      newColor = adjustColor(context, color!);
    }

    switch (type) {
      case TextType.label:
        style = material.Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(fontWeight: FontWeight.w300, color: newColor);
        break;
      case TextType.labelEmphasised:
        style = material.Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(fontWeight: FontWeight.w400, color: newColor);
        break;
      case TextType.error:
        style = material.Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w500,
            color: newColor ?? Theme.of(context).colorScheme.error);
        break;
      case TextType.tiny:
        style = material.Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w300, fontSize: 10, color: newColor);
        break;
      case TextType.body:
        style = material.Theme.of(context)
            .textTheme
            .bodyMedium!
            .copyWith(fontWeight: FontWeight.w300, color: newColor);
        break;
      case TextType.largeTitle:
        style = material.Theme.of(context)
            .textTheme
            .titleLarge!
            .copyWith(color: newColor);
        break;
      case TextType.name:
        style = material.Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: newColor, fontWeight: FontWeight.w400, fontSize: 15);
        break;
      case TextType.labelLow:
        style = material.Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: newColor ?? Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.w400,
            fontSize: 12);
        break;
    }

    return material.Text(
      text,
      style: style,
      softWrap: softwrap,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
