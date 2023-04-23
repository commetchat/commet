import 'package:commet/ui/pages/settings/categories/account/settings_category_account.dart';
import 'package:commet/ui/pages/settings/categories/app/settings_category_app.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';

class SettingsMenu {
  late List<SettingsCategory> settings;

  SettingsMenu() {
    settings = List.from([
      SettingsCategoryAccount(),
      SettingsCategoryAppearence(),
    ]);
  }
}
