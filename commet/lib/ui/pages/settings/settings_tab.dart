import 'package:flutter/material.dart';

class SettingsTab {
  final String label;
  final Widget Function(BuildContext context) pageBuilder;
  final IconData? icon;

  SettingsTab(this.label, this.pageBuilder, {this.icon});
}
