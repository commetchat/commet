import 'package:commet/client/components/push_notification/push_notification_component.dart';
import 'package:commet/client/matrix/components/push_notifications/matrix_push_notification_component.dart';
import 'package:commet/ui/pages/settings/categories/app/notification_settings/notifier_component_view/matrix_notifier_component_view.dart';
import 'package:flutter/material.dart';

class PushNotificationComponentDebugView extends StatefulWidget {
  const PushNotificationComponentDebugView(this.pushNotificationComponent,
      {super.key});
  final PushNotificationComponent pushNotificationComponent;
  @override
  State<PushNotificationComponentDebugView> createState() =>
      _PushNotificationComponentDebugViewState();
}

class _PushNotificationComponentDebugViewState
    extends State<PushNotificationComponentDebugView> {
  @override
  Widget build(BuildContext context) {
    if (widget.pushNotificationComponent is MatrixPushNotificationComponent) {
      return MatrixNotifierComponentView(
          widget.pushNotificationComponent as MatrixPushNotificationComponent);
    }

    return const Placeholder(
      color: Colors.red,
    );
  }
}
