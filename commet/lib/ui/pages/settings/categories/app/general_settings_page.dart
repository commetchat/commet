import 'package:commet/main.dart';
import 'package:commet/ui/pages/setup/menus/check_for_updates.dart';
import 'package:commet/utils/update_checker.dart';
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

  String get labelUrlPreviewInEncryptedChatTitle => Intl.message(
      "URL Preview in Encrypted Chats",
      desc:
          "Label for the toggle for enabling and disabling use of url previews in encrypted chats",
      name: "labelUrlPreviewInEncryptedChatTitle");

  String get labelUrlPreviewInEncryptedChatDescription => Intl.message(
      "This will expose any URLs sent in your encrypted chats to your homeserver in order to fetch the preview",
      desc:
          "description for the toggle for enabling and disabling use of url previews in encrypted chats",
      name: "labelUrlPreviewInEncryptedChatDescription");

  String get labelAppBehaviourTitle =>
      Intl.message("App Behaviour",
          desc: "Header for the app behaviour section in settings",
          name: "labelAppBehaviourTitle");

  String get labelAskBeforeDeletingMessageToggle => Intl.message("Ask before deleting messages",
      desc: "Label for the toggle for enabling and disabling message deletion confirmation",
      name: "labelAskBeforeDeletingMessageToggle");

  String get labelAskBeforeDeletingMessageDescription => Intl.message(
      "Enables the pop-up asking for confirmation when deleting a message.",
      desc: "Label describing what 'asking before deleting messages' even means",
      name: "labelAskBeforeDeletingMessageDescription");

  String get labelMessageEffectsTitle => Intl.message("Message Effects",
      desc:
          "Header for the settings tile for message effects, such as confetti",
      name: "labelMessageEffectsTitle");

  String get labelMessageEffectsDescription => Intl.message(
      "Messages can be sent with additional effects, such as confetti",
      desc: "Label describing what message effects are",
      name: "labelMessageEffectsDescription");

  String get labelMediaPreviewSettingsTitle => Intl.message("Media Preview",
      desc: "Header for the settings tile for for media preview toggles",
      name: "labelMediaPreviewSettingsTitle");

  String get labelMediaPreviewPrivateRoomsToggle => Intl.message(
        "Private Rooms",
        desc:
            "Short label for the private rooms toggle in media previews section",
        name: "labelMediaPreviewPrivateRoomsToggle",
      );

  String get labelMediaPreviewPrivateRoomsToggleDescription => Intl.message(
      "Toggle previewing of images, videos, stickers and urls in private chats",
      desc: "Label describing toggle of media previews for private rooms",
      name: "labelMediaPreviewPrivateRoomsToggleDescription");

  String get labelMediaPreviewPublicRoomsToggle => Intl.message(
        "Public Rooms",
        desc:
            "Short label for the private rooms toggle in media previews section",
        name: "labelMediaPreviewPublicRoomsToggle",
      );

  String get labelMediaPreviewPublicRoomsToggleDescription => Intl.message(
      "Toggle previewing of images, videos, stickers and urls in public chat rooms",
      desc: "Label describing toggle of media previews for public rooms",
      name: "labelMediaPreviewPublicRoomsToggleDescription");

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
              title: labelUrlPreviewInEncryptedChatTitle,
              description: labelUrlPreviewInEncryptedChatDescription,
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
            if (UpdateChecker.shouldCheckForUpdates)
              CheckForUpdatesSettingWidget(),
          ]),
        ),
        const SizedBox(
          height: 10,
        ),
        Panel(
          header: labelAppBehaviourTitle,
          mode: TileType.surfaceContainerLow,
          child: Column(children: [
            settingToggle(
              preferences.askBeforeDeletingMessageEnabled,
              title: labelAskBeforeDeletingMessageToggle,
              description: labelAskBeforeDeletingMessageDescription,
              onChanged: (value) async {
                await preferences.setAskBeforeDeletingMessageEnabled(value);
                setState(() {});
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
        const SizedBox(
          height: 10,
        ),
        Panel(
          header: labelMediaPreviewSettingsTitle,
          mode: TileType.surfaceContainerLow,
          child: Column(children: [
            settingToggle(
              preferences.previewMediaInPrivateRooms,
              title: labelMediaPreviewPrivateRoomsToggle,
              description: labelMediaPreviewPrivateRoomsToggleDescription,
              onChanged: (value) async {
                await preferences.setMediaPreviewInPrivateRooms(value);
                setState(() {});
              },
            ),
            settingToggle(
              preferences.previewMediaInPublicRooms,
              title: labelMediaPreviewPublicRoomsToggle,
              description: labelMediaPreviewPublicRoomsToggleDescription,
              onChanged: (value) async {
                await preferences.setMediaPreviewInPublicRooms(value);
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
