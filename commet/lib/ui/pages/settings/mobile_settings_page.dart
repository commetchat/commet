import 'package:commet/ui/pages/settings/settings_button.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../navigation/navigation_utils.dart';

class MobileSettingsPage extends StatefulWidget {
  const MobileSettingsPage({required this.settings, this.buttons, super.key});
  final List<SettingsButton>? buttons;
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
      child: Tile.low1(
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
                  child: ListView(children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tabs.length,
                      itemBuilder: (context, categoryIndex) {
                        return m.Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: m.Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (categoryIndex != 0) const tiamat.Seperator(),
                              if (tabs[categoryIndex].title != null)
                                tiamat.Text.labelLow(
                                  tabs[categoryIndex].title!,
                                ),
                              ListView.builder(
                                shrinkWrap: true,
                                itemCount: tabs[categoryIndex].tabs.length,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, tabIndex) {
                                  return button(
                                    label: tabs[categoryIndex]
                                        .tabs[tabIndex]
                                        .label!,
                                    icon:
                                        tabs[categoryIndex].tabs[tabIndex].icon,
                                    onTap: () {
                                      setState(() {
                                        NavigationUtils.navigateTo(
                                            context,
                                            SettingsSubPage(
                                                makeScrollable:
                                                    tabs[categoryIndex]
                                                        .tabs[tabIndex]
                                                        .makeScrollable,
                                                builder: tabs[categoryIndex]
                                                    .tabs[tabIndex]
                                                    .pageBuilder!));
                                      });
                                    },
                                  );
                                },
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    if (widget.buttons != null) const Seperator(),
                    if (widget.buttons != null)
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.buttons!.length,
                        itemBuilder: (context, index) {
                          var b = widget.buttons![index];
                          return button(
                              label: b.label,
                              icon: b.icon,
                              color: b.color,
                              onTap: b.onPress);
                        },
                      )
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget button(
      {required String label,
      IconData? icon,
      bool highlighted = false,
      Color? color,
      Function()? onTap}) {
    return SizedBox(
        height: 40,
        child: TextButton(
          label,
          icon: icon,
          highlighted: highlighted,
          onTap: onTap,
          textColor: color,
          iconColor: color,
        ));
  }
}

class SettingsSubPage extends StatelessWidget {
  const SettingsSubPage(
      {required this.builder, super.key, this.makeScrollable = true});
  final Widget Function(BuildContext) builder;
  final bool makeScrollable;
  @override
  Widget build(BuildContext context) {
    return m.Material(
      child: Tile(
        child: SafeArea(
          child: m.Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                if (makeScrollable)
                  ListView(
                    children: [
                      const SizedBox(
                        height: 70,
                      ),
                      builder(context)
                    ],
                  ),
                if (!makeScrollable)
                  m.Padding(
                    padding: const EdgeInsets.fromLTRB(0, 70, 0, 0),
                    child: builder(context),
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
