import 'package:flutter/material.dart';

class ThemeChanger extends StatefulWidget {
  final ThemeData initialTheme;
  final MaterialApp Function(BuildContext context, ThemeData theme)
      materialAppBuilder;

  const ThemeChanger(
      {Key? key, required this.initialTheme, required this.materialAppBuilder})
      : super(key: key);

  @override
  _ThemeChangerState createState() => _ThemeChangerState();

  static void setTheme(BuildContext context, ThemeData theme) {
    var state = context.findAncestorStateOfType<_ThemeChangerState>()
        as _ThemeChangerState;

    state.setState(() {
      state.theme = theme;
    });
  }
}

class _ThemeChangerState extends State<ThemeChanger> {
  late ThemeData theme;

  @override
  void initState() {
    super.initState();
    theme = widget.initialTheme;
  }

  @override
  Widget build(BuildContext context) {
    return widget.materialAppBuilder(context, theme);
  }
}
