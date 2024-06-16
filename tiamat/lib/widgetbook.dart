import 'package:flutter/material.dart';
import 'package:tiamat/config/config.dart';
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
    WidgetbookTheme(
        name: "Dark (Glass)",
        data: ThemeDark.theme
            .copyWith(extensions: [GlassSettings(), ThemeSettings()])),
    WidgetbookTheme(name: "Light", data: ThemeLight.theme),
    WidgetbookTheme(
        name: "Light (Glass)",
        data: ThemeLight.theme
            .copyWith(extensions: [GlassSettings(), ThemeSettings()])),
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
