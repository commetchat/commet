import 'package:commet/client/components/push_notification/android/unified_push_notifier.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/components/push_notification/push_notification_component.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/general_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/app/notification_settings/notifier_debug_view.dart';
import 'package:commet/ui/pages/setup/menus/unified_push_setup.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  Notifier? notifier;
  GlobalKey pushGatewayKey = GlobalKey();
  bool isPushGatewayLoading = false;

  String get notificationSettingsNotSupported =>
      Intl.message("Push notifications are not supported on this system",
          name: "notificationSettingsNotSupported",
          desc: "Message to display when push notifications are not supported");

  @override
  void initState() {
    super.initState();
    notifier = NotificationManager.notifier;
  }

  bool get canConfigureNotifications =>
      BuildConfig.ENABLE_GOOGLE_SERVICES == false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (canConfigureNotifications)
          Column(
            children: [
              Panel(
                mode: tiamat.TileType.surfaceContainerLow,
                header: "Push Notifications",
                child: buildNotificationSettings(),
              ),
              const SizedBox(
                height: 10,
              ),
              if (notifier is UnifiedPushNotifier)
                Panel(
                  mode: tiamat.TileType.surfaceContainerLow,
                  header: "Push Gateway",
                  child: pushGatewaySelector(),
                ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        if (preferences.developerMode)
          const Panel(
            mode: tiamat.TileType.surfaceContainerLow,
            header: "Registered Pushers",
            child: NotifierDebugView(),
          ),
      ],
    );
  }

  Widget buildNotificationSettings() {
    return Column(
      children: [
        if (PlatformUtils.isLinux)
          Column(
            children: [
              GeneralSettingsPageState.settingToggle(
                preferences.formatNotificationBody,
                title: "Message Body Formatting",
                description: "Apply user formatting in message notifications",
                onChanged: (value) async {
                  setState(() {
                    preferences.setFormatNotificationBody(value);
                  });
                },
              ),
              AnimatedOpacity(
                opacity: preferences.formatNotificationBody ? 1 : 0.3,
                duration: Durations.short4,
                child: IgnorePointer(
                  ignoring: preferences.formatNotificationBody == false,
                  child: Column(
                    children: [
                      GeneralSettingsPageState.settingToggle(
                        preferences.showMediaInNotifications,
                        title: "Show Images",
                        description:
                            "Show images in notifications, if allowed by 'General > Media Preview' settings",
                        onChanged: (value) async {
                          setState(() {
                            preferences.setShowMediaInNotifications(value);
                          });
                        },
                      ),
                      GeneralSettingsPageState.settingToggle(
                        preferences.previewUrlsInNotifications,
                        title: "Preview Urls",
                        description:
                            "Fetch URL previews to show extra information about links in notifications",
                        onChanged: (value) async {
                          setState(() {
                            preferences.setPreviewUrlsInNotifications(value);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        if (notifier is UnifiedPushNotifier) UnifiedPushSetupView(),
      ],
    );

    return tiamat.Text(notificationSettingsNotSupported);
  }

  Widget pushGatewaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        tiamat.DropdownTextField(
            key: pushGatewayKey,
            initialValue: preferences.pushGateway,
            textEditorPlaceholder: "push.example.com",
            editableEntryPlaceholder: "Custom push gateway",
            items: [
              "push.commet.chat",
              if (notifier is UnifiedPushNotifier)
                "matrix.gateway.unifiedpush.org"
            ]),
        tiamat.Button(
          text: CommonStrings.promptApply,
          isLoading: isPushGatewayLoading,
          onTap: onPushGatewaySelected,
        )
      ],
    );
  }

  Future<void> onPushGatewaySelected() async {
    var value = (pushGatewayKey.currentState as DropdownTextFieldState).value;
    preferences.setPushGateway(value);

    setState(() {
      isPushGatewayLoading = true;
    });

    await PushNotificationComponent.updateAllPushers();

    setState(() {
      isPushGatewayLoading = false;
    });
  }
}
