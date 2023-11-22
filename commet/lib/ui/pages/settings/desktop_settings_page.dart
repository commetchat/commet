import 'package:commet/ui/pages/settings/settings_button.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as m;

import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class DesktopSettingsPage extends StatefulWidget {
  const DesktopSettingsPage({required this.settings, this.buttons, super.key});
  final List<SettingsCategory> settings;
  final List<SettingsButton>? buttons;
  @override
  State<DesktopSettingsPage> createState() => DesktopSettingsPageState();
}

class DesktopSettingsPageState extends State<DesktopSettingsPage> {
  late List<SettingsCategory> categories;
  int selectedCategoryIndex = 0;
  int selectedTabIndex = 0;

  static ValueKey backButtonKey =
      const ValueKey("DESKTOP_SETTINGS_PAGE_BACK_BUTTON");

  @override
  void initState() {
    categories = widget.settings;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return m.Material(
      color: m.Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tabSelector(context),
          Expanded(
            child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOutCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween(
                      begin: const Offset(0.0, 1.5),
                      end: const Offset(0.0, 0.0),
                    ).animate(animation),
                    child: child,
                  );
                },
                child: categories[selectedCategoryIndex]
                        .tabs[selectedTabIndex]
                        .makeScrollable
                    ? SingleChildScrollView(child: buildContent())
                    : buildContent()),
          )
        ],
      ),
    );
  }

  Widget buildContent() {
    return Tile(
      key: ValueKey(selectedTabIndex),
      child: selectedCategoryIndex < categories.length &&
              selectedTabIndex < categories[selectedCategoryIndex].tabs.length
          ? settingsTab(categories[selectedCategoryIndex]
              .tabs[selectedTabIndex]
              .pageBuilder!)
          : null,
    );
  }

  Widget tabSelector(BuildContext context) {
    return Tile.low1(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: 240,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: CircleButton(
                      key: backButtonKey,
                      radius: 25,
                      icon: m.Icons.arrow_back,
                      onPressed: () => Navigator.of(context).pop(),
                    )),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView(children: [
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: categories.length,
                      itemBuilder: (context, categoryIndex) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (categoryIndex != 0) const tiamat.Seperator(),
                            if (categories[categoryIndex].title != null)
                              tiamat.Text.labelLow(
                                  categories[categoryIndex].title!),
                            tabListBuilder(categoryIndex)
                          ],
                        );
                      },
                    ),
                    if (widget.buttons != null) const Seperator(),
                    if (widget.buttons != null)
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: widget.buttons!.length,
                        itemBuilder: (context, index) {
                          return button(
                              label: widget.buttons![index].label,
                              icon: widget.buttons![index].icon,
                              onTap: widget.buttons![index].onPress,
                              color: widget.buttons![index].color);
                        },
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListView tabListBuilder(int categoryIndex) {
    return ListView.builder(
      shrinkWrap: true,
      itemBuilder: (context, tabIndex) {
        return button(
            label: categories[categoryIndex].tabs[tabIndex].label!,
            icon: categories[categoryIndex].tabs[tabIndex].icon,
            highlighted: categoryIndex == selectedCategoryIndex &&
                tabIndex == selectedTabIndex,
            onTap: () {
              setState(() {
                selectedCategoryIndex = categoryIndex;
                selectedTabIndex = tabIndex;
              });
            });
      },
      itemCount: categories[categoryIndex].tabs.length,
    );
  }

  Widget button(
      {required String label,
      IconData? icon,
      bool highlighted = false,
      Color? color,
      Function()? onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
      child: SizedBox(
          height: 40,
          width: 200,
          child: TextButton(
            label,
            icon: icon,
            highlighted: highlighted,
            onTap: onTap,
            textColor: color,
            iconColor: color,
          )),
    );
  }

  Widget settingsTab(Widget Function(BuildContext context) builder) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: builder(context),
    );
  }
}
