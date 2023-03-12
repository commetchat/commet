import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:tiamat/config/style/theme_glass.dart';
import 'package:tiamat/config/style/theme_light.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

export './atoms/text.dart';

@WidgetbookTheme(name: 'Dark')
ThemeData darkTheme() => ThemeDark.theme;

@WidgetbookTheme(name: 'Light')
ThemeData lightTheme() => ThemeLight.theme;

@WidgetbookTheme(name: 'Glass')
ThemeData glassTheme() => ThemeGlass.theme;

@WidgetbookApp.material(name: 'Tiamat', devices: [Apple.iPhone12, Apple.iMacM1])
class App {}
