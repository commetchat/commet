import 'package:flutter/material.dart';

class SettingsTab {
  final String? label;
  final Widget Function(BuildContext context)? pageBuilder;
  final IconData? icon;
  final bool seperator;

  SettingsTab({this.label, this.pageBuilder, this.icon, this.seperator = false});
}
