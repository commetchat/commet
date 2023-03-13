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
  late List<SettingsTab> tabs;
  int selectedTabIndex = 0;

  @override
  void initState() {
    tabs = SettingsMenu().settings;
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
              ListView.builder(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  if (tabs[index].seperator) {
                    if (tabs[index].label == null) return Seperator();
                    return Padding(
                      padding: EdgeInsets.fromLTRB(s(16), s(8), s(8), s(8)),
                      child: tiamat.Text.label(
                        tabs[index].label!,
                        // style:
                        //     Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).disabledColor),
                      ),
                    );
                  }
                  return SizedBox(
                      child: TextButton(
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
    );
  }
}

class SettingsSubPage extends StatelessWidget {
  const SettingsSubPage({required this.builder, super.key});
  final Widget Function(BuildContext) builder;
  @override
  Widget build(BuildContext context) {
    return Tile.low2(
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
