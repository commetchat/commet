import 'package:commet/config/style/theme_light.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../../config/app_config.dart';
import '../../../config/style/theme_changer.dart';
import '../../../config/style/theme_dark.dart';
import '../../../config/style/theme_glass.dart';
import '../../atoms/background.dart';
import '../../atoms/circle_button.dart';
import '../../atoms/seperator.dart';
import '../../atoms/simple_text_button.dart';
import '../../navigation/navigation_utils.dart';

class MobileSettingsPage extends StatefulWidget {
  const MobileSettingsPage({super.key});

  @override
  State<MobileSettingsPage> createState() => _MobileSettingsPageState();
}

class _MobileSettingsPageState extends State<MobileSettingsPage> {
  late List<SettingsTab> tabs;
  int selectedTabIndex = 0;

  @override
  void initState() {
    tabs = List.empty(growable: true);

    tabs.add(SettingsTab(
        label: "Settings 1",
        pageBuilder: (context) => Column(children: [
              SimpleTextButton("Light Theme",
                  onTap: () => setState(() {
                        ThemeChanger.setTheme(context, ThemeLight().theme);
                      })),
              SimpleTextButton("Dark Theme",
                  onTap: () => setState(() {
                        ThemeChanger.setTheme(context, ThemeDark().theme);
                      })),
              SimpleTextButton("Glass Theme",
                  onTap: () => setState(() {
                        ThemeChanger.setTheme(context, ThemeGlass().theme);
                      })),
            ])));

    tabs.add(SettingsTab(label: "Settings 2", pageBuilder: (context) => Placeholder()));

    tabs.add(SettingsTab(label: "More Settings", seperator: true));

    tabs.add(SettingsTab(label: "Settings 3", pageBuilder: (context) => Placeholder()));

    tabs.add(SettingsTab(label: "Settings 4", pageBuilder: (context) => Placeholder()));

    tabs.add(SettingsTab(seperator: true));

    tabs.add(SettingsTab(label: "Settings 5", pageBuilder: (context) => Placeholder()));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Background.low1(
        context,
        child: Padding(
          padding: EdgeInsets.all(s(8.0)),
          child: SizedBox(
            width: s(240),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(s(8.0)),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: CircleButton(
                        radius: 25,
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.of(context).pop(),
                      )),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    if (tabs[index].seperator) {
                      if (tabs[index].label == null) return Seperator();
                      return Padding(
                        padding: EdgeInsets.fromLTRB(s(16), s(8), s(8), s(8)),
                        child: Text(
                          tabs[index].label!,
                          style:
                              Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).disabledColor),
                        ),
                      );
                    }
                    return SizedBox(
                        height: s(40),
                        width: s(200),
                        child: SimpleTextButton(
                          tabs[index].label!,
                          onTap: () {
                            setState(() {
                              NavigationUtils.navigateTo(context, SettingsSubPage(builder: tabs[index].pageBuilder!));
                            });
                          },
                        ));
                  },
                  itemCount: tabs.length,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSubPage extends StatelessWidget {
  const SettingsSubPage({required this.builder, super.key});
  final Widget Function(BuildContext) builder;
  @override
  Widget build(BuildContext context) {
    return Background.low2(
      context,
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Back"),
          ),
          builder(context)
        ],
      ),
    );
  }
}
