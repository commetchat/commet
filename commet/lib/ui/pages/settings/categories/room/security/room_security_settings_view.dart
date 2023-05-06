import 'package:commet/generated/l10n.dart';
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
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
      mode: tiamat.TileType.surfaceLow2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tiamat.Text.labelEmphasised(T.current.enableEncryptionPrompt),
                tiamat.Text.labelLow(T.current.encryptionCannotBeDisabled)
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
