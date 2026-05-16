import 'package:commet/ui/organisms/particle_player/particle_system_confetti.dart';
import 'package:commet/ui/pages/settings/desktop_settings_page.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:starfield/renderer/particle_system_renderer.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class UpdateInstalledDialog extends StatefulWidget {
  const UpdateInstalledDialog({super.key, this.onDonateTapped});
  final Function()? onDonateTapped;
  @override
  State<UpdateInstalledDialog> createState() => _UpdateInstalledDialogState();
}

class _UpdateInstalledDialogState extends State<UpdateInstalledDialog> {
  MessageEffectConfetti? confetti;

  String get updateInstalledContent => Intl.message(
      "Thank you for updating! Please consider donating to support the project so we can continue to deliver great updates!",
      desc:
          "Content for the dialog which is shown when an update has been installed",
      name: "updateInstalledContent");

  @override
  void initState() {
    confetti = MessageEffectConfetti();
    confetti?.init().then((_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentGeometry.center,
      children: [
        if (confetti?.system != null)
          SizedBox(
              width: 500,
              height: 200,
              child: ParticleSystemRenderer(system: confetti!.system!)),
        SizedBox(
            width: 500,
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      tiamat.Text.label(updateInstalledContent),
                      Material(
                          clipBehavior: Clip.antiAlias,
                          color: ColorScheme.of(context).surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();

                              widget.onDonateTapped?.call();
                            },
                            child: SizedBox(
                              height: 60,
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 8,
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      color: Colors.redAccent,
                                    ),
                                    tiamat.Text.label(
                                        DesktopSettingsPageState.promptDonate),
                                  ],
                                ),
                              ),
                            ),
                          )),
                      Material(
                          clipBehavior: Clip.antiAlias,
                          color: ColorScheme.of(context).surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: SizedBox(
                              height: 40,
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 8,
                                  children: [
                                    tiamat.Text(CommonStrings.promptPoliteNo),
                                  ],
                                ),
                              ),
                            ),
                          )),
                    ])))
      ],
    );
  }
}
