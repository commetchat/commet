import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_common.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

class ThemeBase {
  static ThemeData theme(ColorScheme scheme) => ThemeData(
      brightness: scheme.brightness,
      fontFamily: "RobotoCustom",
      fontFamilyFallback: ThemeCommon.fontFamilyFallback(),
      useMaterial3: true,
      extensions: const [
        ThemeSettings(caulkBorders: true, caulkBorderRadius: 1),
        ExtraColors(
            codeHighlight: Color(0xffc678dd),
            linkColor: Color.fromARGB(255, 120, 120, 255))
      ],
      colorScheme: scheme,
      listTileTheme: ListTileThemeData(
        tileColor: scheme.surface,
      ),
      canvasColor: scheme.surface,
      iconTheme: IconThemeData(color: scheme.secondary),
      shadowColor: Colors.black.withAlpha(100),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ))),
      dividerTheme: DividerThemeData(color: scheme.surfaceContainerHigh),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: scheme.primary.withAlpha(100),
      ),
      dialogTheme: DialogTheme(
          backgroundColor: scheme.surface, shadowColor: Colors.black),
      switchTheme:
          SwitchThemeData(thumbColor: WidgetStatePropertyAll(scheme.secondary)),
      dividerColor: scheme.outline,
      textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.white10),
        foregroundColor: WidgetStatePropertyAll<Color>(Colors.grey.shade300),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            color: Colors.white,
          ),
        ),
      )));
}
