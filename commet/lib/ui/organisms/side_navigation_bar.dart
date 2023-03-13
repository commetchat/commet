import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/organisms/add_space_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiamat/tiamat.dart';

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
  late Map<String, GlobalKey<TimelineViewerState>> timelines = {};

  @override
  void initState() {
    _clientManager = Provider.of<ClientManager>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 70.0,
        child: SpaceSelector(
          _clientManager.spaces,
          width: 70,
          onSpaceInsert: _clientManager.onSpaceAdded.stream,
          header: Column(
            children: [
              ImageButton(
                // tooltip: "Home",

                size: 70,
                icon: Icons.home,
                onTap: () {
                  widget.onHomeSelected?.call();
                },
              ),
            ],
          ),
          footer: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                child: ImageButton(
                  // tooltip: "Add a Space",
                  size: 70,
                  icon: Icons.add,
                  onTap: () {
                    PopupDialog.show(context, content: const AddSpaceDialog(), title: "Add Space");
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                child: ImageButton(
                  // tooltip: "Settings",
                  size: 70,
                  icon: Icons.settings,
                  onTap: () {
                    NavigationUtils.navigateTo(context, const SettingsPage());
                  },
                ),
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
