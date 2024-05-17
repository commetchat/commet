import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:tiamat/config/style/theme_light.dart';

class ThemeChanger extends StatefulWidget {
  final ThemeData initialTheme;
  final Widget Function(BuildContext context, ThemeData theme)
      materialAppBuilder;
  final bool Function() shouldFollowSystemTheme;
  final ThemeData Function() getLightTheme;
  final ThemeData Function() getDarkTheme;

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

  static void updateSystemTheme(BuildContext context) {
    var state = context.findAncestorStateOfType<ThemeChangerState>()
        as ThemeChangerState;

    state.didChangePlatformBrightness();
  }
}

class ThemeChangerState extends State<ThemeChanger>
    with WidgetsBindingObserver {
  late ThemeData theme;

  @override
  void initState() {
    super.initState();
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;

    if (widget.shouldFollowSystemTheme()) {
      if (brightness == Brightness.light) {
        theme = widget.getLightTheme();
      } else if (brightness == Brightness.dark) {
        theme = widget.getDarkTheme();
      }
    } else {
      theme = widget.initialTheme;
    }

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    if (widget.shouldFollowSystemTheme()) {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      if (brightness == Brightness.light) {
        setTheme(widget.getLightTheme());
      } else if (brightness == Brightness.dark) {
        setTheme(widget.getDarkTheme());
      }
    }
  }

  void setTheme(ThemeData theme) {
    setState(() {
      this.theme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.materialAppBuilder(context, theme);
  }
}
