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
  State<NotificationSettingsPage> createState() => _GeneralSettingsPage();
}

class _GeneralSettingsPage extends State<NotificationSettingsPage> {
  Notifier? notifier;

  @override
  void initState() {
    super.initState();
    notifier = notificationManager.notifier;
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      header: "Push Notifications",
      child: buildNotificationSettings(),
    );
  }

  Widget buildNotificationSettings() {
    if (notifier is UnifiedPushNotifier) {
      return UnifiedPushSetupView();
    }

    return tiamat.Text("Push notifications are not supported on this system");
  }
}
