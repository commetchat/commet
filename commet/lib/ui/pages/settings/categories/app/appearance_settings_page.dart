import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/general_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/app/theme_settings/theme_settings_widget.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/scaled_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as m;
import 'package:intl/intl.dart';
import 'package:tiamat/config/config.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  String get labelSettingsAppTheme => Intl.message("Theme",
      name: "labelSettingsAppTheme",
      desc: "Label for theme section of app appearance");

  String get labelAppScale => Intl.message("App Scale",
      name: 'labelAppScale',
      desc:
          "Label for the setting which controls the UI scale of the overall app");

  String get labelUseRoomAvatars => Intl.message("Use room avatars",
      name: "labelUseRoomAvatars",
      desc: "Label for enabling using room avatars instead of icons");

  String get labelEnableRoomIconsDescription =>
      Intl.message("Show room avatar images instead of icons",
          name: "labelEnableRoomIconsDescription",
          desc: "Description for the enable room icons setting");

  String get labelUseRoomAvatarPlaceholders =>
      Intl.message("Use placeholder avatars",
          name: "labelUseRoomAvatarPlaceholders",
          desc: "Label for enabling generic icons in the appearance settings");

  String get labelUseRoomAvatarPlaceholdersDescription => Intl.message(
      "When a room does not have an avatar set, or using them is disabled, fallback to a generic color + first letter placeholder for the image",
      name: "labelUseRoomAvatarPlaceholdersDescription",
      desc: "Description for the enable generic icons setting");

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        themeSettings(context),
        const SizedBox(
          height: 10,
        ),
        Panel(
          header: labelAppScale,
          mode: TileType.surfaceContainerLow,
          child: const UIScaleSelector(),
        ),
        const SizedBox(
          height: 10,
        ),
        Panel(
          header: "Other Options",
          mode: TileType.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Column(
              children: [
                GeneralSettingsPageState.settingToggle(
                  preferences.showRoomAvatars,
                  title: labelUseRoomAvatars,
                  description: labelEnableRoomIconsDescription,
                  onChanged: (value) async {
                    setState(() {
                      preferences.setShowRoomAvatars(value);
                    });
                  },
                ),
                const Seperator(),
                GeneralSettingsPageState.settingToggle(
                  preferences.usePlaceholderRoomAvatars,
                  title: labelUseRoomAvatarPlaceholders,
                  description: labelUseRoomAvatarPlaceholdersDescription,
                  onChanged: (value) async {
                    setState(() {
                      preferences.setUsePlaceholderRoomAvatars(value);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget themeSettings(BuildContext context) {
    return Column(
      children: [
        Panel(
          header: labelSettingsAppTheme,
          mode: TileType.surfaceContainerLow,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
              child: GeneralSettingsPageState.settingToggle(
                preferences.shouldFollowSystemTheme,
                title: "Follow System Brightness",
                description: "Automatically follow system Light / Dark mode",
                onChanged: (value) async {
                  setState(() {
                    preferences.setShouldFollowSystemBrightness(value);
                  });

                  var theme = await preferences.resolveTheme();
                  if (context.mounted) ThemeChanger.setTheme(context, theme);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
              child: GeneralSettingsPageState.settingToggle(
                preferences.shouldFollowSystemColors,
                title: "Follow System Colors",
                description: "Automatically follow system color scheme",
                onChanged: (value) async {
                  setState(() {
                    preferences.setShouldFollowSystemColors(value);
                  });
                  var theme = await preferences.resolveTheme();
                  if (context.mounted) ThemeChanger.setTheme(context, theme);
                },
              ),
            ),
            const Seperator(),
            const ThemeListWidget(),
          ]),
        ),
      ],
    );
  }
}

class UIScaleSelector extends StatefulWidget {
  const UIScaleSelector({super.key});

  @override
  State<UIScaleSelector> createState() => _UIScaleSelectorState();
}

class _UIScaleSelectorState extends State<UIScaleSelector> {
  double value = 1;

  @override
  void initState() {
    value = preferences.appScale;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return m.Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Row(
        children: [
          SizedBox(width: 30, child: tiamat.Text(value.toStringAsPrecision(2))),
          Expanded(
              child: Slider(
            min: 0.5,
            max: preferences.developerMode ? 3 : 2,
            value: value,
            divisions: preferences.developerMode ? 25 : 15,
            onChanged: (value) {
              setState(() {
                this.value = value;
              });
            },
          )),
          Button.secondary(
            text: CommonStrings.promptApply,
            onTap: () {
              double newValue = value;
              preferences.setAppScale(newValue);
              ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
                return newValue;
              };
            },
          )
        ],
      ),
    );
  }
}
