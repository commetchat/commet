import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../navigation/navigation_utils.dart';

class MobileSettingsPage extends StatefulWidget {
  const MobileSettingsPage({required this.settings, super.key});
  final List<SettingsCategory> settings;

  @override
  State<MobileSettingsPage> createState() => _MobileSettingsPageState();
}

class _MobileSettingsPageState extends State<MobileSettingsPage> {
  late List<SettingsCategory> tabs;
  int selectedTabIndex = 0;
  int selectedCategoryIndex = 0;

  @override
  void initState() {
    tabs = widget.settings;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return m.Material(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
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
                          if (categoryIndex != 0) const tiamat.Seperator(),
                          tiamat.Text.labelLow(
                            tabs[categoryIndex].title,
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
    return m.Material(
      child: Tile.low1(
        child: SafeArea(
          child: m.Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                ListView(
                  children: [
                    const SizedBox(
                      height: 70,
                    ),
                    builder(context)
                  ],
                ),
                m.Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleButton(
                    radius: 25,
                    icon: m.Icons.arrow_back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
