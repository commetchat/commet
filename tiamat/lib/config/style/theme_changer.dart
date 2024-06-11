import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:tiamat/config/style/theme_json_converter.dart';
import 'package:tiamat/config/style/theme_light.dart';

class ThemeChanger extends StatefulWidget {
  final ThemeData initialTheme;
  final Widget Function(BuildContext context, ThemeData theme)
      materialAppBuilder;
  final bool Function() shouldFollowSystemTheme;
  final Future<ThemeData> Function() getLightTheme;
  final Future<ThemeData> Function() getDarkTheme;

  const ThemeChanger(
      {Key? key,
      required this.getDarkTheme,
      required this.getLightTheme,
      required this.initialTheme,
      required this.materialAppBuilder,
      required this.shouldFollowSystemTheme})
      : super(key: key);

  @override
  ThemeChangerState createState() => ThemeChangerState();

  static void setTheme(BuildContext context, ThemeData theme) {
    var state = context.findAncestorStateOfType<ThemeChangerState>()
        as ThemeChangerState;

    state.setTheme(theme);
  }

  static void setThemeFromFile(BuildContext context, File file) {
    var state = context.findAncestorStateOfType<ThemeChangerState>()
        as ThemeChangerState;

    state.setThemeFromFile(file);
  }

  static void updateSystemTheme(BuildContext context) {
    var state = context.findAncestorStateOfType<ThemeChangerState>()
        as ThemeChangerState;

    state.didChangePlatformBrightness();
  }

  static ThemeData currentTheme(BuildContext context) {
    var state = context.findAncestorStateOfType<ThemeChangerState>()
        as ThemeChangerState;

    return state.theme;
  }
}

class ThemeChangerState extends State<ThemeChanger>
    with WidgetsBindingObserver {
  late ThemeData theme;

  File? themeFile;
  StreamSubscription? fileObserver;

  @override
  void initState() {
    super.initState();
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;

    theme = widget.initialTheme;

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangePlatformBrightness() async {
    if (widget.shouldFollowSystemTheme()) {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      if (brightness == Brightness.light) {
        setTheme(await widget.getLightTheme());
      } else if (brightness == Brightness.dark) {
        setTheme(await widget.getDarkTheme());
      }
    }
  }

  void setTheme(ThemeData theme) {
    setState(() {
      this.theme = theme;
    });
  }

  void setThemeFromFile(File file) {
    fileObserver?.cancel();
    themeFile = file;

    if (Platform.isWindows) {
      fileObserver = file.parent.watch().listen(onThemeFileChanged);
    } else {
      fileObserver = file.watch().listen(onThemeFileChanged);
    }

    print("Listening for theme file changes");

    _setThemeFromFile(file);
  }

  onThemeFileChanged(FileSystemEvent event) {
    print("Received file event: $event");
    if (event.path == themeFile?.path) {
      _setThemeFromFile(File(event.path));
    }
  }

  void _setThemeFromFile(File file) async {
    var data = await file.readAsString();
    var json = const JsonDecoder().convert(data);

    var theme = ThemeJsonConverter.fromJson(json, file);
    if (theme != null) {
      setTheme(theme);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.materialAppBuilder(context, theme);
  }
}
