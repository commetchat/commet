import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/ui/organisms/add_space_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../atoms/side_panel_button.dart';
import '../molecules/popup_dialog.dart';
import '../molecules/space_selector.dart';
import '../molecules/timeline_viewer.dart';
import '../navigation/navigation_utils.dart';
import '../pages/settings/settings_page.dart';

class SideNavigationBar extends StatefulWidget {
  const SideNavigationBar({super.key, this.onSpaceSelected, this.onHomeSelected, this.onSettingsSelected});

  final void Function(int index)? onSpaceSelected;
  final void Function()? onHomeSelected;
  final void Function()? onSettingsSelected;

  @override
  State<SideNavigationBar> createState() => _SideNavigationBarState();
}

class _SideNavigationBarState extends State<SideNavigationBar> {
  late ClientManager _clientManager;
  late GlobalKey<TimelineViewerState> timelineKey = GlobalKey<TimelineViewerState>();
  late Map<String, GlobalKey<TimelineViewerState>> timelines = Map();

  @override
  void initState() {
    _clientManager = Provider.of<ClientManager>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: s(70.0),
        child: SpaceSelector(
          _clientManager.spaces,
          onSpaceInsert: _clientManager.onSpaceAdded.stream,
          header: Column(
            children: [
              SidePanelButton(
                tooltip: "Home",
                icon: Icons.home,
                onTap: () {
                  widget.onHomeSelected?.call();
                },
              ),
            ],
          ),
          footer: Column(
            children: [
              SidePanelButton(
                tooltip: "Add a Space",
                icon: Icons.add,
                onTap: () {
                  PopupDialog.Show(context, AddSpaceDialog(), title: "Add Space");
                },
              ),
              SidePanelButton(
                tooltip: "Settings",
                icon: Icons.settings,
                onTap: () {
                  NavigationUtils.navigateTo(context, SettingsPage());
                },
              ),
            ],
          ),
          showSpaceOwnerAvatar: false,
          onSelected: (index) {
            widget.onSpaceSelected?.call(index);
          },
        ));
  }
}
