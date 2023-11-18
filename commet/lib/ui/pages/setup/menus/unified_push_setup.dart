import 'dart:async';
import 'dart:typed_data';

import 'package:commet/main.dart';
import 'package:commet/ui/pages/setup/setup_menu.dart';
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
    return UnifiedPushSetupView(this, key: key);
  }

  @override
  Stream<SetupMenuState> get onStateChanged => controller.stream;

  @override
  SetupMenuState state = SetupMenuState.canProgress;

  @override
  Future<void> submit() async {
    var state = key.currentState as UnifiedPushSetupViewState;

    var enabled = state.unifiedPushEnabled;
    var endpoint = state.endpoint;

    await preferences.setUnifiedPushEnabled(enabled);
    if (endpoint != null) {
      await preferences.setUnifiedPushEndpoint(endpoint);
    }

    notificationManager.init();
  }
}

class UnifiedPushSetupView extends StatefulWidget {
  const UnifiedPushSetupView(this.setup, {super.key});
  final UnifiedPushSetup setup;

  @override
  State<UnifiedPushSetupView> createState() => UnifiedPushSetupViewState();
}

class UnifiedPushSetupViewState extends State<UnifiedPushSetupView> {
  bool unifiedPushEnabled = false;
  String? distributor;
  String? endpoint;
  bool loading = true;

  final Map<String, String> knownDistributors = {"io.heckel.ntfy": "ntfy"};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const MarkdownBody(data: """
# Unified Push
This version of Commet was built without Google Play Services. In order to receive push notifications, you will need to use [Unified Push](https://unifiedpush.org/). 

If you already have a Unified Push compatible distributor app installed, you can configure it below
"""),
        const Seperator(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const tiamat.Text.label("Enable Unified Push"),
            tiamat.Switch(
              state: unifiedPushEnabled,
              onChanged: (value) {
                setState(() {
                  unifiedPushEnabled = value;
                });

                if (value) {
                  enableUnifiedPush();
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
          tiamat.Text.labelLow(distributor == null
              ? "No distributor could be found"
              : knownDistributors[distributor] ?? distributor!),
          tiamat.Text.labelEmphasised("Endpoint"),
          tiamat.Text.labelLow(endpoint == null
              ? "No endpoint was registered, something went wrong"
              : endpoint!),
        ],
      ),
    );
  }

  void enableUnifiedPush() async {
    await UnifiedPush.initialize(
        onNewEndpoint: onNewEndpoint,
        onRegistrationFailed: onRegistrationFailed,
        onMessage: onMessage,
        onUnregistered: onUnregistered);

    if (mounted) {
      await UnifiedPush.registerAppWithDialog(context);
      var foundDistributor = await UnifiedPush.getDistributor();

      setState(() {
        loading = false;
        distributor = foundDistributor;
      });
    }
  }

  void onNewEndpoint(String newEndpoint, String instance) {
    print("Received endpoint: $newEndpoint");
    setState(() {
      endpoint = newEndpoint;
    });
  }

  void onRegistrationFailed(String instance) {
    print("Registration failed :(");
  }

  void onMessage(Uint8List message, String instance) {
    print("Message received!");
  }

  void onUnregistered(String instance) {
    print("on Unregistered!");
  }
}
