import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_menu.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import '../../../config/app_config.dart';

import '../../navigation/navigation_utils.dart';

class MobileSettingsPage extends StatefulWidget {
  const MobileSettingsPage({super.key});

  @override
  State<MobileSettingsPage> createState() => _MobileSettingsPageState();
}

class _MobileSettingsPageState extends State<MobileSettingsPage> {
  late List<SettingsCategory> tabs;
  int selectedTabIndex = 0;
  int selectedCategoryIndex = 0;

  @override
  void initState() {
    tabs = SettingsMenu().settings;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return m.Material(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(s(8.0)),
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
              Flexible(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: tabs.length,
                  itemBuilder: (context, categoryIndex) {
                    return m.Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: m.Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (categoryIndex != 0) tiamat.Seperator(),
                          tiamat.Text.labelLow(
                            tabs[categoryIndex].title!,
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: tabs[categoryIndex].tabs.length,
                            itemBuilder: (context, tabIndex) {
                              return SizedBox(
                                  height: 40,
                                  child: TextButton(
                                    tabs[categoryIndex].tabs[tabIndex].label!,
                                    icon:
                                        tabs[categoryIndex].tabs[tabIndex].icon,
                                    onTap: () {
                                      setState(() {
                                        NavigationUtils.navigateTo(
                                            context,
                                            SettingsSubPage(
                                                builder: tabs[categoryIndex]
                                                    .tabs[tabIndex]
                                                    .pageBuilder!));
                                      });
                                    },
                                  ));
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
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
    return Tile.low1(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(s(8.0)),
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
              builder(context)
            ],
          ),
        ),
      ),
    );
  }
}
