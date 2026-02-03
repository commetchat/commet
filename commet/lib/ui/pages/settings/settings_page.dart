import 'package:commet/client/client.dart';
import 'package:commet/client/components/donation_awards/donation_awards_component.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/user_panel.dart' show UserPanelView;
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/settings/donation_rewards_confirmation.dart';
import 'package:commet/ui/pages/settings/mobile_settings_page.dart';
import 'package:commet/ui/pages/settings/settings_button.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/utils/links/link_utils.dart';
import 'package:flutter/material.dart';

import 'desktop_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage(
      {required this.settings,
      this.buttons,
      this.showDonateButton = false,
      super.key});
  final List<SettingsCategory> settings;
  final List<SettingsButton>? buttons;
  final bool showDonateButton;

  @override
  Widget build(BuildContext context) {
    return pickChatView(context);
  }

  Widget pickChatView(BuildContext context) {
    if (Layout.desktop) {
      return DesktopSettingsPage(
        settings: settings,
        buttons: buttons,
        showDonateButton: showDonateButton,
        onDonateButtonTapped: onDonateButtonTapped,
      );
    }
    if (Layout.mobile) {
      return MobileSettingsPage(
        settings: settings,
        buttons: buttons,
        showDonateButton: showDonateButton,
        onDonateButtonTapped: onDonateButtonTapped,
      );
    }

    throw Exception(
        "No SettingsPage has been defined for the current build config");
  }

  onDonateButtonTapped(BuildContext context) async {
    var client = await AdaptiveDialog.pickOne<dynamic>(
      title: "Pick an account to donate with",
      context,
      items: [
        ...clientManager!.clients,
        "anonymous",
      ],
      itemBuilder: (context, item, callback) {
        if (item is Client) {
          return UserPanelView(
            displayName: item.self!.displayName,
            avatar: item.self!.avatar,
            detail: item.self!.identifier,
            onClicked: callback,
          );
        }

        return UserPanelView(
          color: Theme.of(context).colorScheme.primaryContainer,
          avatarColor: Theme.of(context).colorScheme.primaryContainer,
          displayName: "No Account",
          detail: "Donate without linking to an account",
          onClicked: callback,
        );
      },
    );

    SecretClientIdentifier? secret;
    String? userId;

    if (client == null) return;

    if (client is Client) {
      userId = client.self!.identifier;
      var comp = client.getComponent<DonationAwardsComponent>();
      secret = await comp?.getClientSecret();

      if (secret == null) {
        AdaptiveDialog.show(context,
            builder: (_) => Text("Error: Unable to get client token"));
      }
    }

    if (secret == null) {
      userId = "null";
    }

    Log.i("Donating with encrypted username hash: ${secret?.encryptedHash}");

    final String host = "https://commet.chat";

    var time = DateTime.now();

    var url = Uri.parse(
        "$host/donate/#client_reference_id=${Uri.encodeComponent(secret?.encryptedHash ?? "null")}&matrix_id=${Uri.encodeComponent(userId!)}&secret=${Uri.encodeComponent(secret?.clientSecret ?? "null")}");

    if (client is Client) {
      preferences.setRunningDonationCheckFlow(client.identifier, time);
    }

    LinkUtils.open(url, context: context, filterTrackingParameters: false);

    if (userId != "null" && secret != null) {
      AdaptiveDialog.show(context,
          builder: (context) => DonationRewardsConfirmation(
                client: client,
                identifier: secret!,
                didOpenDonationWindow: true,
                since: time,
              ),
          dismissible: false);
    }
  }
}
