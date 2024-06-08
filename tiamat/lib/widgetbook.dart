import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:tiamat/config/style/theme_light.dart';
import 'package:tiamat/config/style/theme_you.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'dart:io' show Platform;
// Import the generated directories variable
import 'widgetbook.directories.g.dart';

void main() {
  runApp(WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  WidgetbookApp({Key? key}) : super(key: key);

  final ThemeAddon themes = MaterialThemeAddon(themes: [
    WidgetbookTheme(name: "Dark", data: ThemeDark.theme),
    WidgetbookTheme(name: "Light", data: ThemeLight.theme),
    WidgetbookTheme(
        name: "Material You (Green Light)",
        data: ThemeYou.theme(Colors.green, Brightness.light)),
    WidgetbookTheme(
        name: "Material You (Green Dark)",
        data: ThemeYou.theme(Colors.green, Brightness.dark))
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
