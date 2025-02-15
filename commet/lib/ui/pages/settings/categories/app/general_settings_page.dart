import 'package:commet/main.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => GeneralSettingsPageState();
}

class GeneralSettingsPageState extends State<GeneralSettingsPage> {
  bool enableTenor = false;
  bool enableEncryptedPreview = false;

  String get labelThirdPartyServicesTitle =>
      Intl.message("Third party services",
          desc: "Header for the third party services section in settings",
          name: "labelThirdPartyServicesTitle");

  String get labelGifSearchToggle => Intl.message("Gif search",
      desc: "Label for the toggle for enabling and disabling gif search",
      name: "labelGifSearchToggle");

  String labelGifSearchDescription(proxyUrl) => Intl.message(
      "Enable use of Tenor gif search. Requests will be proxied via $proxyUrl",
      desc: "Explains that gifs will be fetched via proxy",
      args: [proxyUrl],
      name: "labelGifSearchDescription");

  String get labelEncryptedPreview => Intl.message(
      "URL Preview in Encrypted Chats (Experimental)",
      desc:
          "Label for the toggle for enabling and disabling encrypted url preview",
      name: "labelEncryptedPreview");

  String labelEncryptedPreviewDescription(proxyUrl) => Intl.message(
      "Enable use of a proxy server ($proxyUrl) to get url preview in an encrypted chat. The content of these requests will be hidden from your homeserver using Commet's 'encrypted url preview'\nLearn more: https://github.com/commetchat/encrypted_url_preview",
      desc: "Explains briefly how encrypted url preview works",
      args: [proxyUrl],
      name: "labelEncryptedPreviewDescription");

  String get labelMessageEffectsTitle => Intl.message("Message Effects",
      desc:
          "Header for the settings tile for message effects, such as confetti",
      name: "labelMessageEffectsTitle");

  String get labelMessageEffectsDescription => Intl.message(
      "Messages can be sent with additional effects, such as confetti",
      desc: "Label describing what message effects are",
      name: "labelMessageEffectsDescription");

  @override
  void initState() {
    enableTenor = preferences.tenorGifSearchEnabled;
    enableEncryptedPreview = preferences.urlPreviewInE2EEChat;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Panel(
          header: labelThirdPartyServicesTitle,
          mode: TileType.surfaceContainerLow,
          child: Column(children: [
            settingToggle(
              enableTenor,
              title: labelGifSearchToggle,
              description: labelGifSearchDescription(preferences.proxyUrl),
              onChanged: (value) async {
                setState(() {
                  enableTenor = value;
                });
                await preferences.setTenorGifSearch(value);
                setState(() {
                  enableTenor = preferences.tenorGifSearchEnabled;
                });
              },
            ),
            const SizedBox(
              height: 10,
            ),
            settingToggle(
              enableEncryptedPreview,
              title: labelEncryptedPreview,
              description:
                  labelEncryptedPreviewDescription("telescope.commet.chat"),
              onChanged: (value) async {
                setState(() {
                  enableEncryptedPreview = value;
                });
                await preferences.setUseUrlPreviewInE2EEChat(value);
                setState(() {
                  enableEncryptedPreview = preferences.urlPreviewInE2EEChat;
                });
              },
            ),
          ]),
        ),
        const SizedBox(
          height: 10,
        ),
        Panel(
          header: labelMessageEffectsTitle,
          mode: TileType.surfaceContainerLow,
          child: Column(children: [
            settingToggle(
              preferences.messageEffectsEnabled,
              title: labelMessageEffectsTitle,
              description: labelMessageEffectsDescription,
              onChanged: (value) async {
                await preferences.setMessageEffectsEnabled(value);
                setState(() {});
              },
            ),
          ]),
        ),
      ],
    );
  }

  static Row settingToggle(bool state,
      {required String title,
      required String description,
      void Function(bool)? onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tiamat.Text.labelEmphasised(title),
              tiamat.Text.labelLow(description)
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: tiamat.Switch(state: state, onChanged: onChanged),
        )
      ],
    );
  }
}
