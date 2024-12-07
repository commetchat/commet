import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/about/settings_category_about.dart';
import 'package:commet/ui/pages/settings/settings_page.dart';
import 'package:flutter/widgets.dart';

import 'categories/account/settings_category_account.dart';
import 'categories/app/settings_category_app.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  @override
  void initState() {
    preferences.onDeveloperModeChanged.listen((_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(settings: [
      SettingsCategoryAccount(),
      SettingsCategoryApp(),
      SettingsCategoryAbout(),
    ]);
  }
}
