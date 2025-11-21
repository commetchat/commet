import 'package:commet/config/experiments.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/general_settings_page.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class ExperimentsSettingsPage extends StatefulWidget {
  const ExperimentsSettingsPage({super.key});

  @override
  State<ExperimentsSettingsPage> createState() =>
      _ExperimentsSettingsPageState();
}

class _ExperimentsSettingsPageState extends State<ExperimentsSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: tiamat.Text.label(
            "These features are still under development, and may contain bugs or security issues. Enable at your own risk",
          ),
        ),
        Panel(
          header: "Experiments",
          mode: TileType.surfaceContainerLow,
          child: Column(
            children: [
              GeneralSettingsPageState.settingToggle(
                Experiments.voip,
                title: "1:1 Voice and Video Calls",
                description:
                    "Enables peer to peer voice and video calls, using WebRTC",
                onChanged: (value) async {
                  setState(() {
                    Experiments.setVoip(value);
                  });
                },
              ),
              GeneralSettingsPageState.settingToggle(
                Experiments.elementCall,
                title: "Voice/Video Rooms (Element Call)",
                description:
                    "Enables group video and audio calls using LiveKit",
                onChanged: (value) async {
                  setState(() {
                    Experiments.setElementCall(value);
                  });
                },
              ),
              GeneralSettingsPageState.settingToggle(
                Experiments.photoAlbumRooms,
                title: "Photo Album Rooms",
                description:
                    "Share photos and videos, with dedicated album viewer",
                onChanged: (value) async {
                  setState(() {
                    Experiments.setPhotoAlbumRooms(value);
                  });
                },
              ),
              GeneralSettingsPageState.settingToggle(
                Experiments.calendarRooms,
                title: "Calendar Rooms",
                description: "Create a shared calendar using matrix rooms",
                onChanged: (value) async {
                  setState(() {
                    Experiments.setCalendarRoom(value);
                  });
                },
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: tiamat.Text.error(
            "You must restart the app for changes to take effect",
          ),
        ),
      ],
    );
  }
}
