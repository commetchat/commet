import 'dart:async';

import 'package:commet/main.dart';
import 'package:commet/ui/pages/setup/setup_menu.dart';
import 'package:commet/utils/notification/android/unified_push_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:unifiedpush/unifiedpush.dart';

class UnifiedPushSetup implements SetupMenu {
  StreamController<SetupMenuState> controller = StreamController();
  GlobalKey key = GlobalKey();
  @override
  Widget builder(BuildContext context) {
    return UnifiedPushSetupView(key: key);
  }

  @override
  Stream<SetupMenuState> get onStateChanged => controller.stream;

  @override
  SetupMenuState state = SetupMenuState.canProgress;

  @override
  Future<void> submit() async {
    notificationManager.init();
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

  final Map<String, String> knownDistributors = {"io.heckel.ntfy": "ntfy"};

  @override
  void initState() {
    wasUnifiedPushAlreadyConfigured = preferences.unifiedPushEnabled != null;
    notifier = notificationManager.notifier as UnifiedPushNotifier?;
    notifier?.onEndpointChanged.stream.listen((event) {
      setState(() {});
    });

    unifiedPushEnabled = preferences.unifiedPushEnabled == true;

    if (wasUnifiedPushAlreadyConfigured) {
      loading = false;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!wasUnifiedPushAlreadyConfigured) MarkdownBody(data: """
# Unified Push
This version of Commet was built without Google Play Services. In order to receive push notifications, you will need to use [Unified Push](https://unifiedpush.org/). 

If you already have a Unified Push compatible distributor app installed, you can configure it below
"""),
        if (!wasUnifiedPushAlreadyConfigured) Seperator(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tiamat.Text.label("Enable Unified Push"),
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
      return CircularProgressIndicator();
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          tiamat.Text.labelEmphasised("Distributor"),
          tiamat.Text.labelLow(notifier?.distributor == null
              ? "No distributor could be found"
              : knownDistributors[notifier!.distributor] ??
                  notifier!.distributor!),
          tiamat.Text.labelEmphasised("Endpoint"),
          tiamat.Text.labelLow(notifier?.endpoint == null
              ? "No endpoint was registered, something went wrong"
              : notifier!.endpoint!),
        ],
      ),
    );
  }

  void enableUnifiedPush() async {
    await notifier?.init();
    preferences.setUnifiedPushEnabled(true);
    if (mounted) {
      await UnifiedPush.registerAppWithDialog(context);
    }
  }

  void disableUnifiedPush() async {
    preferences.setUnifiedPushEnabled(false);
    notifier?.unregister();
  }
}
