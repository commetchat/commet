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
        linkColor: Color.fromARGB(255, 120, 120, 255),
      ),
    ],
    colorScheme: scheme,
    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    listTileTheme: ListTileThemeData(
      dense: true,
      contentPadding: EdgeInsets.fromLTRB(8, 2, 8, 0),
    ),
    canvasColor: scheme.surface,
    iconTheme: IconThemeData(color: scheme.secondary),
    shadowColor: Colors.black.withAlpha(100),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide.none,
          ),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.surfaceContainerHigh),
    sliderTheme: SliderThemeData(
      inactiveTrackColor: scheme.primary.withAlpha(100),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shadowColor: Colors.black,
    ),
    dividerColor: scheme.outline,
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ),
  );
}
