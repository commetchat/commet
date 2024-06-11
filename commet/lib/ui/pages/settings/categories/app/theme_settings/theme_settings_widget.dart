import 'dart:async';
import 'dart:io';

import 'package:commet/config/preferences.dart';
import 'package:commet/config/theme_config.dart';
import 'package:commet/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/config/style/theme_changer.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:path/path.dart' as path;

class ThemeListWidget extends StatefulWidget {
  const ThemeListWidget({super.key});

  @override
  State<ThemeListWidget> createState() => _ThemeListWidgetState();
}

class _ThemeEntry {
  String name;
  Function(BuildContext context) setter;

  _ThemeEntry(this.name, this.setter);
}

class _ThemeListWidgetState extends State<ThemeListWidget> {
  late List<_ThemeEntry> entries;
  StreamSubscription? customThemesDirSub;

  String get labelThemeDark => Intl.message("Dark Theme",
      name: "labelThemeDark", desc: "Label for the dark theme");

  String get labelThemeLight => Intl.message("Light Theme",
      name: "labelThemeLight", desc: "Label for the light theme");

  String get labelThemeAmoled => Intl.message("Amoled",
      name: "labelThemeAmoled", desc: "Label for the light theme");

  List<_ThemeEntry> get defaultThemes => [
        _ThemeEntry(labelThemeLight, (BuildContext context) async {
          preferences.setTheme(AppTheme.light);
          var theme = await preferences.resolveTheme(
              overrideBrightness: Brightness.light);
          if (context.mounted) ThemeChanger.setTheme(context, theme);
        }),
        _ThemeEntry(labelThemeDark, (BuildContext context) async {
          preferences.setTheme(AppTheme.dark);
          var theme = await preferences.resolveTheme(
              overrideBrightness: Brightness.dark);
          if (context.mounted) ThemeChanger.setTheme(context, theme);
        }),
        _ThemeEntry(labelThemeAmoled, (BuildContext context) async {
          preferences.setTheme(AppTheme.amoled);
          var theme = await preferences.resolveTheme(
              overrideBrightness: Brightness.dark);

          if (context.mounted) ThemeChanger.setTheme(context, theme);
        }),
      ];

  @override
  void initState() {
    entries = List.from(defaultThemes);
    initCustomThemes();
    super.initState();
  }

  @override
  void dispose() {
    customThemesDirSub?.cancel();
    super.dispose();
  }

  void initCustomThemes() async {
    loadCustomThemes();
    var dir = await ThemeConfig.getCustomThemesDir();
    customThemesDirSub =
        dir.watch(recursive: true).listen(onCustomThemesDirUpdated);
  }

  void loadCustomThemes() async {
    var themes = await ThemeConfig.getCustomThemes();

    var customEntries = themes.map((e) {
      var name = path.basenameWithoutExtension(e.path);

      return _ThemeEntry(name, (context) async {
        var file = await ThemeConfig.getFileFromThemeDir(e);
        ThemeChanger.setThemeFromFile(context, file);
      });
    });
    var newEntries = List<_ThemeEntry>.from(defaultThemes);
    newEntries.addAll(customEntries);

    setState(() {
      entries = newEntries;
    });
  }

  void onCustomThemesDirUpdated(FileSystemEvent event) {
    print("Themes dir updated, reloading items!");
    loadCustomThemes();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var entry in entries)
          tiamat.TextButton(entry.name, onTap: () => entry.setter(context)),
      ],
    );
  }
}
