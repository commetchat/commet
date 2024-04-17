import 'dart:async';

import 'package:commet/main.dart';
import 'package:commet/ui/molecules/settings_entry_bool.dart';
import 'package:commet/ui/pages/settings/categories/app/voip_settings/voip_debug_settings.dart';
import 'package:flutter/widgets.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class VoipSettingsPage extends StatefulWidget {
  const VoipSettingsPage({super.key});

  @override
  State<VoipSettingsPage> createState() => _VoipSettingsPage();
}

class _VoipSettingsPage extends State<VoipSettingsPage> {
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    sub = preferences.onSettingChanged.listen((event) => setState(() {}));
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        tiamat.Panel(
          mode: tiamat.TileType.surfaceLow2,
          header: "Call Connection",
          child: SettingsEntryBool(
            preferences.useFallbackTurnServer,
            title: "Use TURN Fallback",
            description:
                "Calls cannot be connected without a TURN server. If your homeserver does not provide a TURN server, fall back to using '${preferences.fallbackTurnServer}'. Your IP address will be revealed to this server when establishing calls",
            onChanged: preferences.setUseFallbackTurnServer,
          ),
        ),
        if (preferences.developerMode)
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: tiamat.Panel(
              header: "WebRTC Debug Menu",
              mode: tiamat.TileType.surfaceLow1,
              child: VoipDebugSettings(),
            ),
          ),
      ],
    );
  }
}
