import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/seperator.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

const String exampleText = "The quick brown fox jumped over the lazy dog";

@WidgetbookUseCase(name: 'Label', type: Text)
Widget wbtextLabelUseCase(BuildContext context) {
  return const material.Center(
    child: Text.label(exampleText),
  );
}

@WidgetbookUseCase(name: 'Tiny', type: Text)
Widget wbtextTinyUseCase(BuildContext context) {
  return const material.Center(
    child: Text.tiny(exampleText),
  );
}

@WidgetbookUseCase(name: 'Body', type: Text)
Widget wbtextBodyUseCase(BuildContext context) {
  return const material.Center(
    child: Text.body(exampleText),
  );
}

@WidgetbookUseCase(name: 'Error', type: Text)
Widget wbtextErrorUseCase(BuildContext context) {
  return const material.Center(
    child: Text.error(exampleText),
  );
}

@WidgetbookUseCase(name: 'Title', type: Text)
Widget wbtextTitleUseCase(BuildContext context) {
  return const material.Center(
    child: material.Padding(
      padding: EdgeInsets.all(8.0),
      child: Text.largeTitle(exampleText),
    ),
  );
}

@WidgetbookUseCase(name: 'Name', type: Text)
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

@WidgetbookUseCase(name: 'All', type: Text)
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
          Align(alignment: Alignment.centerRight, child: Text.labelEmphasised(exampleText)),
          Align(alignment: Alignment.centerRight, child: Text.label(exampleText)),
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
          Align(alignment: Alignment.centerRight, child: Text.error(exampleText)),
        ],
      ),
    ),
  );
}

enum TextType { label, labelEmphasised, error, tiny, body, largeTitle, name }

class Text extends StatelessWidget {
  const Text(this.text, {super.key, this.type = TextType.label, this.color});
  final String text;
  final TextType type;
  final Color? color;

  const Text.label(this.text, {Key? key})
      : type = TextType.label,
        color = null,
        super(key: key);

  const Text.labelEmphasised(
    this.text, {
    Key? key,
  })  : type = TextType.labelEmphasised,
        color = null,
        super(key: key);

  const Text.error(this.text, {Key? key})
      : type = TextType.error,
        color = null,
        super(key: key);

  const Text.tiny(this.text, {Key? key})
      : type = TextType.tiny,
        color = null,
        super(key: key);

  const Text.body(this.text, {Key? key})
      : type = TextType.body,
        color = null,
        super(key: key);

  const Text.largeTitle(this.text, {Key? key})
      : type = TextType.largeTitle,
        color = null,
        super(key: key);

  const Text.name(this.text, {Key? key, this.color})
      : type = TextType.name,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle style;

    switch (type) {
      case TextType.label:
        style = material.Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w300);
        break;
      case TextType.labelEmphasised:
        style = material.Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w400);
        break;
      case TextType.error:
        style = material.Theme.of(context)
            .textTheme
            .bodyMedium!
            .copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.error);
        break;
      case TextType.tiny:
        style = material.Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w300, fontSize: 10);
        break;
      case TextType.body:
        style = material.Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w300);
        break;
      case TextType.largeTitle:
        style = material.Theme.of(context).textTheme.titleLarge!;
        break;
      case TextType.name:
        style = material.Theme.of(context)
            .textTheme
            .bodyMedium!
            .copyWith(color: color, fontWeight: FontWeight.w400, fontSize: 15);
        break;
    }

    return material.Text(
      text,
      style: style,
    );
  }
}
