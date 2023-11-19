import 'package:commet/client/components/push_notification/push_notification_component.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/setup/menus/unified_push_setup.dart';
import 'package:commet/utils/notification/android/unified_push_notifier.dart';
import 'package:commet/utils/notification/notifier.dart';
import 'package:flutter/widgets.dart';

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

  @override
  void initState() {
    super.initState();
    notifier = notificationManager.notifier;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Panel(
          header: "Push Notifications",
          child: buildNotificationSettings(),
        ),
        const SizedBox(
          height: 10,
        ),
        Panel(
          header: "Push Gateway",
          child: pushGatewaySelector(),
        ),
      ],
    );
  }

  Widget buildNotificationSettings() {
    if (notifier is UnifiedPushNotifier) {
      return const UnifiedPushSetupView();
    }

    return tiamat.Text("Push notifications are not supported on this system");
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
          text: "Apply",
          isLoading: isPushGatewayLoading,
          onTap: onPushGatewaySelected,
        )
      ],
    );
  }

  onPushGatewaySelected() async {
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
