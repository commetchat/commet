import 'package:commet/main.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  bool developerOptions = false;
  bool stickerCompatibility = false;
  String get labelSettingsDeveloperMode => Intl.message("Developer mode",
      desc: "Header for the settings to enable developer mode",
      name: "labelSettingsDeveloperMode");

  String get labelSettingsDeveloperModeExplanation =>
      Intl.message("Shows extra information, useful for developers",
          desc: "Explains what developer mode does",
          name: "labelSettingsDeveloperModeExplanation");

  String get labelStickerCompatibility => Intl.message("Sticker compatibility",
      desc: "Header for the settings to enable sticker compatibility mode",
      name: "labelStickerCompatibility");

  String get labelSettingsStickerCompatibilityExplanation => Intl.message(
      "In some matrix clients, sending a sticker as 'm.sticker' will cause the sticker to not load correctly. Enabling this setting will send stickers as 'm.image' which will allow them to render correctly",
      desc: "Explains what sticker compatibility mode does",
      name: "labelSettingsStickerCompatibilityExplanation");

  @override
  void initState() {
    developerOptions = preferences.developerMode;
    stickerCompatibility = preferences.stickerCompatibilityMode;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Panel(
          header: labelSettingsDeveloperMode,
          mode: TileType.surfaceLow2,
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tiamat.Text.labelEmphasised(labelSettingsDeveloperMode),
                    tiamat.Text.labelLow(labelSettingsDeveloperModeExplanation)
                  ],
                ),
                tiamat.Switch(
                  state: developerOptions,
                  onChanged: (value) async {
                    setState(() {
                      developerOptions = value;
                    });
                    await preferences.setDeveloperMode(value);
                    setState(() {
                      developerOptions = preferences.developerMode;
                    });
                  },
                )
              ],
            )
          ]),
        ),
        const SizedBox(
          height: 10,
        ),
        Panel(
          header: labelStickerCompatibility,
          mode: TileType.surfaceLow2,
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tiamat.Text.labelEmphasised(labelStickerCompatibility),
                      tiamat.Text.labelLow(
                          labelSettingsStickerCompatibilityExplanation)
                    ],
                  ),
                ),
                tiamat.Switch(
                  state: stickerCompatibility,
                  onChanged: (value) async {
                    setState(() {
                      stickerCompatibility = value;
                    });
                    await preferences.setStickerCompatibilityMode(value);
                    setState(() {
                      stickerCompatibility =
                          preferences.stickerCompatibilityMode;
                    });
                  },
                )
              ],
            )
          ]),
        )
      ],
    );
  }
}
