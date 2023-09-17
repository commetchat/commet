import 'package:flutter/material.dart';

class SettingsButton {
  final String label;
  final Function() onPress;
  final IconData? icon;
  final Color? color;
  SettingsButton({
    required this.label,
    required this.onPress,
    this.icon,
    this.color,
  });
}
