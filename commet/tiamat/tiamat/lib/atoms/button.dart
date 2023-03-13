import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

@WidgetbookUseCase(name: 'Default', type: Button)
Widget wb_Button(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 50,
          child: Center(child: Button()),
        ),
        SizedBox(
          width: 200,
          height: 50,
          child: Center(child: Button.secondary()),
        ),
        SizedBox(
          width: 200,
          height: 50,
          child: Center(child: Button.success()),
        ),
        SizedBox(
          width: 200,
          height: 50,
          child: Center(child: Button.danger()),
        ),
        SizedBox(
          width: 200,
          height: 50,
          child: Center(child: Button.critical()),
        ),
      ],
    ),
  );
}

enum ButtonType {
  Primary,
  Secondary,
  Success,
  Danger,
  Critical,
}

class Button extends StatelessWidget {
  const Button({super.key, this.text = "Hello, World!", this.onTap, this.type = ButtonType.Primary});
  final ButtonType type;
  final String text;
  final Function? onTap;

  const Button.secondary({Key? key, this.text = "Hello, World!", this.onTap})
      : type = ButtonType.Secondary,
        super(key: key);

  const Button.success({Key? key, this.text = "Hello, World!", this.onTap})
      : type = ButtonType.Success,
        super(key: key);

  const Button.danger({Key? key, this.text = "Hello, World!", this.onTap})
      : type = ButtonType.Danger,
        super(key: key);

  const Button.critical({Key? key, this.text = "Hello, World!", this.onTap})
      : type = ButtonType.Critical,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    ButtonStyle style;

    switch (type) {
      case ButtonType.Primary:
        style = Theme.of(context).elevatedButtonTheme.style!;
        break;
      case ButtonType.Secondary:
        style = Theme.of(context)
            .elevatedButtonTheme
            .style!
            .copyWith(backgroundColor: MaterialStatePropertyAll(Theme.of(context).extension<ExtraColors>()!.highlight));
        break;
      case ButtonType.Success:
        style = Theme.of(context)
            .elevatedButtonTheme
            .style!
            .copyWith(backgroundColor: MaterialStatePropertyAll(Colors.green.shade400));

        break;
      case ButtonType.Danger:
        style = Theme.of(context).elevatedButtonTheme.style!.copyWith(
            backgroundColor: MaterialStatePropertyAll(Colors.transparent),
            shadowColor: MaterialStatePropertyAll(Colors.transparent),
            side: MaterialStatePropertyAll(BorderSide(color: Theme.of(context).colorScheme.error, width: 1)));
        break;
      case ButtonType.Critical:
        style = Theme.of(context)
            .elevatedButtonTheme
            .style!
            .copyWith(backgroundColor: MaterialStatePropertyAll(Theme.of(context).colorScheme.error));
        break;
    }

    return ElevatedButton(
        style: style,
        onPressed: () {
          onTap?.call();
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: tiamat.Text.label(text!),
        ));
  }
}
