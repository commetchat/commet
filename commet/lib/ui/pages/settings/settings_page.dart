import 'package:commet/config/build_config.dart';
import 'package:commet/ui/pages/settings/mobile_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import 'desktop_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return pickChatView();
  }

  Widget pickChatView() {
    if (BuildConfig.DESKTOP) return DesktopSettingsPage();
    if (BuildConfig.MOBILE) return MobileSettingsPage();
    throw Exception("No SettingsPage has been defined for the current build config");
  }
}
