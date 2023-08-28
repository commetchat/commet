import 'package:commet/ui/pages/settings/settings_tab.dart';

abstract class SettingsCategory {
  String? get title;
  List<SettingsTab> get tabs;
}
