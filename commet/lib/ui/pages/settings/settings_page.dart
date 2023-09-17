import 'package:commet/config/build_config.dart';
import 'package:commet/ui/pages/settings/mobile_settings_page.dart';
import 'package:commet/ui/pages/settings/settings_button.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/utils/orientation.dart';
import 'package:flutter/widgets.dart';

import 'desktop_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.settings, this.buttons, super.key});
  final List<SettingsCategory> settings;
  final List<SettingsButton>? buttons;

  @override
  Widget build(BuildContext context) {
    return pickChatView(context);
  }

  Widget pickChatView(BuildContext context) {
    if (BuildConfig.DESKTOP) {
      return DesktopSettingsPage(
        settings: settings,
        buttons: buttons,
      );
    }
    if (BuildConfig.MOBILE) {
      return MobileSettingsPage(
        settings: settings,
        buttons: buttons,
      );
    }

    if (BuildConfig.WEB) {
      if (OrientationUtils.getCurrentOrientation(context) ==
          Orientation.landscape) {
        return DesktopSettingsPage(
          settings: settings,
          buttons: buttons,
        );
      } else {
        return MobileSettingsPage(
          settings: settings,
          buttons: buttons,
        );
      }
    }
    throw Exception(
        "No SettingsPage has been defined for the current build config");
  }
}
