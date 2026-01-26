import 'dart:async';

import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/general_settings_page.dart';
import 'package:commet/ui/pages/setup/setup_menu.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class UpdateCheckerSetup implements SetupMenu {
  StreamController<SetupMenuState> controller = StreamController();

  GlobalKey key = GlobalKey();

  @override
  Widget builder(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tiamat.Text.largeTitle("Check for updates"),
        tiamat.Text.label(
            "Would you like Commet to automatically check for new updates?"),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
              decoration: BoxDecoration(
                color: ColorScheme.of(context).surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CheckForUpdatesSettingWidget(),
              )),
        ),
      ],
    );
  }

  @override
  Stream<SetupMenuState> get onStateChanged => controller.stream;

  @override
  SetupMenuState state = SetupMenuState.canProgress;

  @override
  Future<void> submit() async {
    if (preferences.checkForUpdates == null) {
      preferences.setCheckForUpdates(false);
    }
  }
}

class CheckForUpdatesSettingWidget extends StatefulWidget {
  const CheckForUpdatesSettingWidget({super.key});

  @override
  State<CheckForUpdatesSettingWidget> createState() =>
      _CheckForUpdatesSettingWidgetState();
}

class _CheckForUpdatesSettingWidgetState
    extends State<CheckForUpdatesSettingWidget> {
  @override
  Widget build(BuildContext context) {
    return GeneralSettingsPageState.settingToggle(
      preferences.checkForUpdates ?? false,
      title: "Check for updates",
      description:
          "Automatically check if there is a newer version of Commet available",
      onChanged: (v) {
        preferences.setCheckForUpdates(v);
        setState(() {});
      },
    );
  }
}
