import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_common.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'dart:io' show Platform;

class ThemeBase {
  static ThemeData theme(Brightness brightness) => ThemeData(
        fontFamily: "RobotoCustom",
        fontFamilyFallback: ThemeCommon.fontFamilyFallback(),
        brightness: brightness,
        useMaterial3: true,
        listTileTheme: ListTileThemeData(
            contentPadding: EdgeInsets.all(0),
            dense: true,
            minTileHeight: 0,
            minLeadingWidth: 0,
            minVerticalPadding: 0),
        expansionTileTheme: ExpansionTileThemeData(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            collapsedShape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tilePadding: EdgeInsets.fromLTRB(8, 0, 8, 0)),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
                shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ))),
        textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
          padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
              EdgeInsets.fromLTRB(8, 0, 8, 0)),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              color: Colors.white,
            ),
          ),
        )),
      );
}
