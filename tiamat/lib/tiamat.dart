import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:tiamat/config/style/theme_glass.dart';
import 'package:tiamat/config/style/theme_light.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

export './atoms/text.dart';
export './atoms/text_button.dart';
export './atoms/avatar.dart';
export './atoms/button.dart';
export './atoms/circle_button.dart';
export './atoms/image_button.dart';
export './atoms/popup_dialog.dart';
export './atoms/seperator.dart';
export './atoms/slider.dart';
export './atoms/switch.dart';
export './atoms/tile.dart';
export './atoms/text_input.dart';
export './atoms/dropdown_selector.dart';
export './atoms/icon_button.dart';

@WidgetbookTheme(name: 'Dark')
ThemeData darkTheme() => ThemeDark.theme;

@WidgetbookTheme(name: 'Light')
ThemeData lightTheme() => ThemeLight.theme;

@WidgetbookTheme(name: 'Glass')
ThemeData glassTheme() => ThemeGlass.theme;

@WidgetbookApp.material(name: 'Tiamat', devices: [Apple.iPhone12, Apple.iMacM1])
class App {}
