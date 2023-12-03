import 'dart:async';

import 'package:commet/client/components/push_notification/android/unified_push_notifier.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/notification_settings_page.dart';
import 'package:commet/ui/pages/setup/setup_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:unifiedpush/unifiedpush.dart';

class UnifiedPushSetup implements SetupMenu {
  StreamController<SetupMenuState> controller = StreamController();
  GlobalKey key = GlobalKey();
  @override
  Widget builder(BuildContext context) {
    return NotificationSettingsPage(key: key);
  }

  @override
  Stream<SetupMenuState> get onStateChanged => controller.stream;

  @override
  SetupMenuState state = SetupMenuState.canProgress;

  @override
  Future<void> submit() async {
    NotificationManager.init();
  }
}

class UnifiedPushSetupView extends StatefulWidget {
  const UnifiedPushSetupView({super.key, this.onToggled});
  final Function(bool enabled)? onToggled;

  @override
  State<UnifiedPushSetupView> createState() => UnifiedPushSetupViewState();
}

class UnifiedPushSetupViewState extends State<UnifiedPushSetupView> {
  bool unifiedPushEnabled = false;
  bool loading = true;
  bool wasUnifiedPushAlreadyConfigured = false;
  UnifiedPushNotifier? notifier;

  String? endpoint;

  String get unifiedPushExplainer => Intl.message("""
# Unified Push
This version of Commet was built without Google Play Services. In order to receive push notifications, you will need to use [Unified Push](https://unifiedpush.org/). 

If you already have a Unified Push compatible distributor app installed, you can configure it below
""",
      name: "unifiedPushExplainer",
      desc: "Explains the need for unified push. Supports markdown");

  String get labelEnableUnifiedPush => Intl.message("Enable Unified Push",
      name: "labelEnableUnifiedPush",
      desc: "Label for the toggle to enable Unified Push");

  String get labelEnableUnifiedPushEndpoint => Intl.message("Endpoint",
      name: "labelEnableUnifiedPushEndpoint",
      desc: "Label for the Unified Push endpoint");

  String get labelUnifiedPushNoEndpointFound => Intl.message(
      "No endpoint found, something went wrong :(",
      name: "labelUnifiedPushNoEndpointFound",
      desc: "Message for when a unified push endpoint could not be registered");

  @override
  void initState() {
    wasUnifiedPushAlreadyConfigured = preferences.unifiedPushEnabled != null;
    notifier = NotificationManager.notifier as UnifiedPushNotifier?;
    notifier?.onEndpointChanged.stream.listen((event) => onEndpointChanged());
    unifiedPushEnabled = preferences.unifiedPushEnabled == true;

    getInitialToken();

    if (wasUnifiedPushAlreadyConfigured) {
      loading = false;
    }

    super.initState();
  }

  void getInitialToken() async {
    var token = await notifier?.getToken();
    setState(() {
      endpoint = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!wasUnifiedPushAlreadyConfigured)
          MarkdownBody(data: unifiedPushExplainer),
        if (!wasUnifiedPushAlreadyConfigured) const Seperator(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tiamat.Text.label(labelEnableUnifiedPush),
            tiamat.Switch(
              state: unifiedPushEnabled,
              onChanged: (value) {
                widget.onToggled?.call(value);

                setState(() {
                  unifiedPushEnabled = value;
                });

                if (value) {
                  enableUnifiedPush();
                } else {
                  disableUnifiedPush();
                }
              },
            ),
          ],
        ),
        if (unifiedPushEnabled)
          Align(
              alignment: Alignment.centerLeft, child: buildUnifiedPushDetails())
      ],
    );
  }

  Widget buildUnifiedPushDetails() {
    if (loading) {
      return const CircularProgressIndicator();
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          tiamat.Text.labelEmphasised(labelEnableUnifiedPushEndpoint),
          tiamat.Text.labelLow(
              endpoint == null ? labelUnifiedPushNoEndpointFound : endpoint!),
        ],
      ),
    );
  }

  void onEndpointChanged() async {
    setState(() {
      endpoint = notifier?.endpoint;
    });
  }

  void enableUnifiedPush() async {
    preferences.setUnifiedPushEnabled(true);
    await notifier?.init();

    if (mounted) {
      await UnifiedPush.registerAppWithDialog(context);
    }

    setState(() {
      loading = false;
      endpoint = notifier?.endpoint;
    });
  }

  void disableUnifiedPush() async {
    await notifier?.unregister();
    setState(() {
      loading = false;
      endpoint = null;
    });
  }
}
