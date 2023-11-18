import 'package:commet/config/build_config.dart';
import 'package:commet/ui/pages/setup/setup_menu.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class SetupPage extends StatefulWidget {
  const SetupPage(this.menus, {super.key});
  final List<SetupMenu> menus;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  int currentMenuIndex = 0;
  late SetupMenu currentMenu;

  @override
  void initState() {
    super.initState();
    currentMenu = widget.menus[currentMenuIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Tile.low1(
        child: Padding(
          padding: const EdgeInsets.all(BuildConfig.MOBILE ? 10 : 50.0),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                tiamat.Text.largeTitle("Before you begin..."),
                Flexible(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Tile.low2(
                          child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: SingleChildScrollView(
                                  child: currentMenu.builder(context)),
                            ),
                          ),
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: tiamat.Button(
                                    text: "Next",
                                    onTap: goNextMenu,
                                  ),
                                ),
                              ),
                              TweenAnimationBuilder(
                                  tween: Tween<double>(
                                      begin: 0,
                                      end: currentMenuIndex /
                                          widget.menus.length),
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, _) {
                                    return LinearProgressIndicator(
                                      value: value,
                                    );
                                  })
                            ],
                          ),
                        ],
                      ))),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  goNextMenu() {
    currentMenu.submit();
    var newIndex = currentMenuIndex + 1;
    setState(() {
      currentMenuIndex = newIndex;
    });

    if (newIndex >= widget.menus.length) {
      Navigator.pop(context);
    } else {
      setState(() {
        currentMenuIndex = newIndex;
        currentMenu = widget.menus[currentMenuIndex];
      });
    }
  }
}
