import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/settings/settings_button.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/utils/color_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as m;

import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class DesktopSettingsPage extends StatefulWidget {
  const DesktopSettingsPage(
      {required this.settings,
      this.buttons,
      this.onDonateButtonTapped,
      super.key});
  final List<SettingsCategory> settings;
  final List<SettingsButton>? buttons;
  final Function(BuildContext context)? onDonateButtonTapped;
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
      child: Foundation(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tabSelector(context),
            Expanded(
              child: categories[selectedCategoryIndex]
                      .tabs[selectedTabIndex]
                      .makeScrollable
                  ? SingleChildScrollView(child: buildContent())
                  : buildContent(),
            )
          ],
        ),
      ),
    );
  }

  Widget buildContent() {
    return Tile(
      caulkPadTop: true,
      caulkPadBottom: true,
      caulkClipTopLeft: true,
      caulkClipBottomLeft: true,
      key: ValueKey(selectedTabIndex),
      child: selectedCategoryIndex < categories.length &&
              selectedTabIndex < categories[selectedCategoryIndex].tabs.length
          ? settingsTab(categories[selectedCategoryIndex]
              .tabs[selectedTabIndex]
              .pageBuilder)
          : null,
    );
  }

  Widget tabSelector(BuildContext context) {
    return Tile.surfaceContainer(
      caulkPadRight: true,
      caulkPadTop: true,
      caulkPadBottom: true,
      caulkClipTopRight: true,
      caulkClipBottomRight: true,
      caulkBorderRight: true,
      child: SizedBox(
        width: 240,
        child: Column(
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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
                                  if (categoryIndex != 0)
                                    const tiamat.Seperator(),
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
            buildDonateButton(context,
                onTap: widget.onDonateButtonTapped?.call(context))
          ],
        ),
      ),
    );
  }

  static Widget buildDonateButton(BuildContext context, {Function()? onTap}) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: AdaptiveContextMenu(
        items: [
          ContextMenuItem(
              text: "Refresh Awards", icon: m.Icons.refresh, onPressed: () {}),
        ],
        child: m.Material(
          clipBehavior: Clip.antiAlias,
          color: ColorUtils.fromHexCode("#CE7A6D"),
          borderRadius: BorderRadius.circular(8),
          child: m.InkWell(
            onTap: onTap,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: m.Icon(
                          m.Icons.favorite,
                          color: ColorUtils.fromHexCode("#73342a"),
                        ),
                      ),
                      tiamat.Text(
                        "Donate",
                        color: ColorUtils.fromHexCode("#73342a"),
                      ),
                    ],
                  )),
            ),
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
            label: categories[categoryIndex].tabs[tabIndex].label,
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
