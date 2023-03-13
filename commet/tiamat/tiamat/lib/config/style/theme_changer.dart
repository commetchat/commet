import 'package:flutter/material.dart';

class ThemeChanger extends StatefulWidget {
  final ThemeData initialTheme;
  final MaterialApp Function(BuildContext context, ThemeData theme) materialAppBuilder;

  const ThemeChanger({Key? key, required this.initialTheme, required this.materialAppBuilder}) : super(key: key);

  @override
  ThemeChangerState createState() => ThemeChangerState();

  static void setTheme(BuildContext context, ThemeData theme) {
    var state = context.findAncestorStateOfType<ThemeChangerState>() as ThemeChangerState;

    state.setTheme(theme);
  }
}

class ThemeChangerState extends State<ThemeChanger> {
  late ThemeData theme;

  @override
  void initState() {
    super.initState();
    theme = widget.initialTheme;
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
