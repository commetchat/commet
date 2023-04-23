import 'package:commet/config/build_config.dart';
import 'package:commet/ui/pages/settings/mobile_settings_page.dart';
import 'package:flutter/widgets.dart';

import 'desktop_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return pickChatView();
  }

  Widget pickChatView() {
    if (BuildConfig.DESKTOP) return const DesktopSettingsPage();
    if (BuildConfig.MOBILE) return const MobileSettingsPage();
    throw Exception(
        "No SettingsPage has been defined for the current build config");
  }
}
