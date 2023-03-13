import 'package:commet/ui/pages/settings/settings_menu.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as m;

import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import '../../../config/app_config.dart';

class DesktopSettingsPage extends StatefulWidget {
  const DesktopSettingsPage({super.key});

  @override
  State<DesktopSettingsPage> createState() => _DesktopSettingsPageState();
}

class _DesktopSettingsPageState extends State<DesktopSettingsPage> {
  late List<SettingsTab> tabs;
  int selectedTabIndex = 0;

  @override
  void initState() {
    tabs = SettingsMenu().settings;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return m.Material(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Tile.low1(
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
                            icon: m.Icons.arrow_back,
                            onPressed: () => Navigator.of(context).pop(),
                          )),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        if (tabs[index].seperator) {
                          if (tabs[index].label == null) return const Seperator();
                          return Padding(
                            padding: EdgeInsets.fromLTRB(s(16), s(8), s(8), s(8)),
                            child: tiamat.Text.label(tabs[index].label!),
                          );
                        }
                        return SizedBox(
                            height: s(40),
                            width: s(200),
                            child: TextButton(
                              tabs[index].label!,
                              highlighted: index == selectedTabIndex,
                              onTap: () {
                                setState(() {
                                  selectedTabIndex = index;
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
          Expanded(
              child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOutCubic,
            //switchOutCurve: Curves.easeInExpo,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position: Tween(
                  begin: const Offset(0.0, 1.5),
                  end: const Offset(0.0, 0.0),
                ).animate(animation),
                child: child,
              );
            },
            child: Tile(
              key: ValueKey(selectedTabIndex),
              child: settingsTab(tabs[selectedTabIndex].pageBuilder!),
            ),
          ))
        ],
      ),
    );
  }

  Widget settingsTab(Widget Function(BuildContext context) builder) {
    return Padding(
      padding: EdgeInsets.all(s(20.0)),
      child: builder(context),
    );
  }
}
