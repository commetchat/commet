import 'package:commet/client/client.dart';
import 'package:commet/ui/pages/settings/categories/space/settings_category_space.dart';
import 'package:commet/ui/pages/settings/settings_page.dart';
import 'package:flutter/widgets.dart';

class SpaceSettingsPage extends StatelessWidget {
  const SpaceSettingsPage({super.key, required this.space});
  final Space space;

  @override
  Widget build(BuildContext context) {
    return SettingsPage(settings: [
      SettingsCategorySpace(
        space,
      ),
    ]);
  }
}
