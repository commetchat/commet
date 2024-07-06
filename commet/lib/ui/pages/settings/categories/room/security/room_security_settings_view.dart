import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class RoomSecuritySettingsView extends StatefulWidget {
  const RoomSecuritySettingsView(
      {super.key,
      this.enableE2EE,
      this.isE2EEEnabled,
      this.supportsE2EE = false});
  final bool? isE2EEEnabled;
  final bool supportsE2EE;
  final Function()? enableE2EE;

  @override
  State<RoomSecuritySettingsView> createState() =>
      _RoomSecuritySettingsViewState();
}

class _RoomSecuritySettingsViewState extends State<RoomSecuritySettingsView> {
  late bool isE2EEEnabled;

  String get promptEnableEncryptionRoomSettings =>
      Intl.message("Enable Encryption",
          name: "promptEnableEncryptionRoomSettings",
          desc: "Short prompt to enable encryption for a room");

  String get encryptionCannotBeDisabledExplanationRoomSettings =>
      Intl.message("If enabled, encryption cannot be disabled later",
          name: "encryptionCannotBeDisabledExplanationRoomSettings",
          desc: "Explains that encryption cannot be disabled once enabled");

  @override
  void initState() {
    isE2EEEnabled = widget.isE2EEEnabled ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.supportsE2EE) buildE2EEToggle(),
      ],
    );
  }

  Widget buildE2EEToggle() {
    return tiamat.Panel(
      mode: tiamat.TileType.surfaceContainerLow,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tiamat.Text.labelEmphasised(promptEnableEncryptionRoomSettings),
                tiamat.Text.labelLow(
                    encryptionCannotBeDisabledExplanationRoomSettings)
              ]),
          IgnorePointer(
            ignoring: isE2EEEnabled,
            child: tiamat.Switch(
              state: isE2EEEnabled,
              onChanged: (value) {
                if (value != true) return;
                setState(() {
                  isE2EEEnabled = true;
                  widget.enableE2EE?.call();
                });
              },
            ),
          )
        ],
      ),
    );
  }
}
