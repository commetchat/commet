import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/pages/settings/categories/account/settings_category_account.dart';
import 'package:commet/ui/pages/settings/categories/app/settings_category_app.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/widgets.dart';
import 'package:scaled_app/scaled_app.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/config/config.dart';

class SettingsMenu {
  late List<SettingsCategory> settings;

  SettingsMenu() {
    settings = List.from([
      SettingsCategoryAccount(),
      SettingsCategoryAppearence(),
    ]);
  }
}
