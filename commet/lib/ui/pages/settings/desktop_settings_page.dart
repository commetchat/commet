import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart';

import '../../atoms/simple_text_button.dart';

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
    tabs = List.empty(growable: true);

    tabs.add(SettingsTab("Settings 1", (context) => Container(color: Colors.red, child: Placeholder())));

    tabs.add(SettingsTab("Settings 2", (context) => Container(color: Colors.blue, child: Placeholder())));

    tabs.add(SettingsTab("Settings 3", (context) => Container(color: Colors.green, child: Placeholder())));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(
              width: 200,
              child: ListView.builder(
                itemBuilder: (context, index) {
                  print(tabs[index].label);
                  return SizedBox(
                      height: 50,
                      width: 200,
                      child: SimpleTextButton(
                        tabs[index].label,
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
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOutCubic,
                //switchOutCurve: Curves.easeInExpo,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween(
                      begin: Offset(0.0, 1.5),
                      end: Offset(0.0, 0.0),
                    ).animate(animation),
                    child: child,
                  );
                },
                child: Container(key: ValueKey(selectedTabIndex), child: tabs[selectedTabIndex].pageBuilder(context)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
