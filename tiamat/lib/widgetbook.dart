import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'widgetbook.directories.g.dart';

import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:tiamat/config/style/theme_glass.dart';
import 'package:tiamat/config/style/theme_light.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

void main() {
  runApp(WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  WidgetbookApp({Key? key}) : super(key: key);

  final ThemeAddon themes = MaterialThemeAddon(themes: [
    WidgetbookTheme(name: "Dark", data: ThemeDark.theme),
    WidgetbookTheme(name: "Light", data: ThemeLight.theme)
  ]);

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      // Use the generated directories variable
      directories: directories,
      addons: [themes],
    );
  }
}
