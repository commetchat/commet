import 'dart:async';

import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/molecules/widget_debug_view.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:commet/ui/pages/settings/app_settings_page.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class UserPanelSettings extends StatefulWidget {
  const UserPanelSettings({this.height = 30, super.key});
  final double height;

  @override
  State<UserPanelSettings> createState() => _UserPanelSettingsState();
}

class _UserPanelSettingsState extends State<UserPanelSettings> {

  StreamSubscription? sub;

  @override
  void initState() {
    sub = WidgetComponent.currentSessions.onListUpdated.listen((_) {
      setState(() {});
    });

    super.initState();
  }


  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double height = widget.height * 0.7;
    double iconHeight = height / 2.5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Row(
        children: [
          if (WidgetComponent.currentSessions.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(height),
              child: Material(
                color: Colors.transparent,
                child: AdaptiveContextMenu(
                  modal: true,
                  items: [
                    tiamat.ContextMenuItem(
                      text: "Running Widgets",
                      customBuilder: (context, onClicked, {closeMenu}) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              tiamat.Text.labelLow("Running Widgets"),
                            ],
                          ),
                        );
                      },
                    ),
                    ...WidgetComponent.currentSessions
                        .map((i) => tiamat.ContextMenuItem(
                              text: i.widgetId,
                              customBuilder: (context, onClicked, {closeMenu}) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                        width: 300,
                                        height: 30,
                                        child: tiamat.TextButton(
                                          i.info.name,
                                          onTap: onClicked,
                                        )),
                                    tiamat.IconButton(
                                      icon: Icons.close,
                                      iconColor: ColorScheme.of(context).error,
                                      onPressed: () {
                                        i.dispose();
                                        closeMenu?.call();
                                      },
                                    ),
                                  ],
                                );
                              },
                              onPressed: () {
                                AdaptiveDialog.show(
                                  context,
                                  builder: (context) {
                                    return SizedBox(
                                        width: 700,
                                        height: 700,
                                        child: WidgetDebugView(
                                            i as MatrixWidgetRunner));
                                  },
                                );
                              },
                            )),
                  ],
                  child: SizedBox(
                      width: height,
                      height: height,
                      child: Stack(
                        children: [
                          tiamat.IconButton(
                            icon: Icons.widgets,
                            size: iconHeight,
                          ),
                          IgnorePointer(
                            ignoring: true,
                            child: Align(
                              alignment: AlignmentGeometry.xy(0.3, 0.3),
                              child: UserPanelView.createPresenceIcon(
                                  context, UserPresenceStatus.online),
                            ),
                          ),
                        ],
                      )),
                ),
              ),
            ),
          SizedBox(
              width: height,
              height: height,
              child: tiamat.IconButton(
                icon: Icons.settings,
                size: iconHeight,
                onPressed: () {
                  NavigationUtils.navigateTo(context, const AppSettingsPage());
                },
              ))
        ],
      ),
    );
  }
}
