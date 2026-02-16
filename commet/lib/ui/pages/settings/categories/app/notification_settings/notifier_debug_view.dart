import 'package:commet/client/components/push_notification/push_notification_component.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/account_selector.dart';
import 'package:commet/ui/pages/settings/categories/app/notification_settings/notifier_component_view/notifier_component_view.dart';
import 'package:flutter/widgets.dart';

class NotifierDebugView extends StatefulWidget {
  const NotifierDebugView({super.key});

  @override
  State<NotifierDebugView> createState() => _NotifierDebugViewState();
}

class _NotifierDebugViewState extends State<NotifierDebugView> {
  PushNotificationComponent? component;

  @override
  void initState() {
    component = clientManager.clients.firstOrNull
        ?.getComponent<PushNotificationComponent>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (clientManager.clients.length > 1)
          AccountSelector(
            clientManager.clients,
            onClientSelected: (client) {
              setState(() {
                component = client.getComponent<PushNotificationComponent>();
              });
            },
          ),
        if (component != null)
          PushNotificationComponentDebugView(
            component!,
            key: ValueKey(
                "push_notification_debug_view:${component!.client.identifier}"),
          ),
      ],
    );
  }
}
