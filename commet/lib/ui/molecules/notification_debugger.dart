import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/push_notification/android/android_notifier.dart';
import 'package:commet/client/components/push_notification/android/firebase_push_notifier.dart';
import 'package:commet/client/components/push_notification/android/unified_push_notifier.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/notifying_list_builder.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:commet/utils/stream_utils.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:unifiedpush/unifiedpush.dart';
import 'package:window_manager/window_manager.dart';

import 'package:http/http.dart' as http;

class NotificationDebugger extends StatefulWidget {
  const NotificationDebugger(
      {this.event, this.room, required this.client, super.key});
  final TimelineEvent? event;
  final Client client;
  final Room? room;
  @override
  State<NotificationDebugger> createState() => _NotificationDebuggerState();
}

class _NotificationDebugStep {
  String name;
  String description;
  bool? passed;

  _NotificationDebugStep(
      {required this.name, required this.description, required this.passed});
}

class _NotificationDebuggerState extends State<NotificationDebugger> {
  NotifyingList<_NotificationDebugStep> steps =
      NotifyingList.empty(growable: true);
  bool running = true;

  @override
  void initState() {
    runTests();
    super.initState();
  }

  bool get usesDesktopNotification =>
      PlatformUtils.isLinux || PlatformUtils.isWindows;

  Future<void> runTests() async {
    if (usesDesktopNotification) {
      await Future.delayed(Duration(seconds: 5));
      await windowManager.minimize();
    }

    if (PlatformUtils.isAndroid) {
      EventBus.openHomeScreen.add(null);
    }

    await Future.delayed(Duration(seconds: 1));

    try {
      if (widget.event case MatrixTimelineEvent event) {
        if (usesDesktopNotification) {
          await shouldNotifyTest(event);
          await handleNotificationTest(event);
        } else {
          await checkPermissions();
          await pushRulesTest(event, widget.room as MatrixRoom);
          await checkPushGateway(event, widget.room as MatrixRoom);
        }
      }
    } catch (e) {
      steps.add(_NotificationDebugStep(
          name: "Tests failed",
          description: "An error occured while running tests: ${e}",
          passed: false));
    }
    setState(() {
      running = false;
    });
  }

  Future<void> pushRulesTest(MatrixTimelineEvent event, MatrixRoom room) async {
    var evaluator = room.matrixRoom.client.pushruleEvaluator;
    var match = evaluator.match(event.event);

    steps.add(_NotificationDebugStep(
        name: "Push Rules",
        description:
            "Check if the event matches your account's defined push rules",
        passed: match.notify));
  }

  Future<void> checkPermissions() async {
    final notifier = NotificationManager.notifier;
    var permission = false;

    if (notifier is UnifiedPushNotifier) {
      permission = await notifier.notifier.checkPermission();
    } else if (notifier is FirebasePushNotifier) {
      permission = await notifier.notifier.checkPermission();
    } else if (notifier is AndroidNotifier) {
      permission = await notifier.checkPermission();
    }

    var step = _NotificationDebugStep(
        name: "Check permissions",
        description:
            "Tests if we have permission from the system to display a notification",
        passed: permission);

    steps.add(step);
  }

  Future<void> shouldNotifyTest(MatrixTimelineEvent event) async {
    final shouldNotify = (widget.room as MatrixRoom).shouldNotify(
      event,
      onNotificationRejected: (reason) {
        var step = _NotificationDebugStep(
            name: "Notification rejected",
            description: "$reason",
            passed: false);

        steps.add(step);
      },
    );

    var step = _NotificationDebugStep(
        name: "Should Notify",
        description:
            "Tests whether the given event should trigger a notification",
        passed: shouldNotify);

    steps.add(step);
  }

  Future<void> checkPushGateway(
      MatrixTimelineEvent event, MatrixRoom room) async {
    var matrixClient = (widget.client as MatrixClient).getMatrixClient();
    var pushers = await matrixClient.getPushers();

    if (BuildConfig.ENABLE_GOOGLE_SERVICES == false) {
      steps.add(_NotificationDebugStep(
          name: "Unified Push Configuration",
          description: "Checks the current config for unified push",
          passed: preferences.unifiedPushEnabled.value == true &&
              preferences.unifiedPushEndpoint.value != null));

      if (preferences.unifiedPushEnabled.value == true) {
        var distributor = await UnifiedPush.getDistributor();

        steps.add(_NotificationDebugStep(
            name: "Unified Push Distributor",
            description: "distributor for unified push: $distributor",
            passed: distributor != null));
      }
    }

    String? pushKey = BuildConfig.ENABLE_GOOGLE_SERVICES
        ? preferences.fcmKey.value
        : preferences.unifiedPushEndpoint.value;

    var pusher = pushers
        ?.where((i) =>
            i.deviceDisplayName == matrixClient.clientName &&
            i.pushkey == pushKey)
        .firstOrNull;

    var step = _NotificationDebugStep(
        name: "Has Registered Pusher",
        description:
            "Tests if the client has registered a push notification service with the homeserver",
        passed: pusher != null);

    steps.add(step);

    if (pusher != null) {
      if (BuildConfig.ENABLE_GOOGLE_SERVICES &&
          pusher.data.additionalProperties["type"] == "fcm") {
        steps.add(_NotificationDebugStep(
            name: "Pusher configuration",
            description:
                "Checks the pusher is configured to use Google services",
            passed: true));
      }

      final url = pusher.data.url!.replace(path: "/_matrix/push/v1/notify");

      final content = {
        "notification": {
          "devices": [
            {
              "app_id": pusher.appId,
              "data": {
                ...pusher.data.additionalProperties,
              },
              "pushkey": pusher.pushkey,
            },
          ],
          "event_id": event.eventId,
          "prio": "high",
          "room_id": room.identifier
        }
      };

      Log.i("Sending to: $url");
      Log.i(
        "Sending test notification: ${content}",
      );

      var startTime = DateTime.now();

      var nextData =
          EventBus.onReceivedPushNotificationData.stream.nextItemAsFuture();

      var result = await http.post(url, body: jsonEncode(content), headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      });

      var step = _NotificationDebugStep(
          name: "Send test notification",
          description:
              "Tests if sending a notification to the registered pusher is accepted",
          passed: result.statusCode == 200);

      steps.add(step);
      try {
        final result = await nextData.timeout(Duration(seconds: 20));
        var endTime = DateTime.now();
        var length = endTime.difference(startTime);
        var step = _NotificationDebugStep(
            name: "Receive notification",
            description:
                "Received data back from push service in ${length.inMilliseconds}ms: $result",
            passed: true);

        steps.add(step);
      } catch (e) {
        if (e is TimeoutException) {
          var step = _NotificationDebugStep(
              name: "Receive notification",
              description:
                  "Did not receive any data back from push service after waiting 20 seconds",
              passed: false);

          steps.add(step);
        } else {
          var step = _NotificationDebugStep(
              name: "Receive notification",
              description:
                  "Unknown error occured waiting for notification data: $e",
              passed: false);

          steps.add(step);
        }
      }
    }
  }

  Future<void> handleNotificationTest(MatrixTimelineEvent event) async {
    final f = (widget.room as MatrixRoom).handleNotification(
      event,
      onNotificationRejected: (reason) {
        var step = _NotificationDebugStep(
            name: "Notification rejected",
            description: "$reason",
            passed: false);

        steps.add(step);
      },
    );

    await f;

    var step = _NotificationDebugStep(
        name: "Handle Notification",
        description: "If you saw a notification, this test passed.",
        passed: null);

    steps.add(step);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 500,
      child: Column(
        children: [
          if (running)
            Column(
              children: [
                if (usesDesktopNotification)
                  tiamat.Text.labelLow(
                      "The app may be minimized while testing. if minimized, wait for atleast 5 seconds before re-opening"),
                CircularProgressIndicator(),
              ],
            ),
          if (!running)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: tiamat.Text.label("Test complete"),
            ),
          Flexible(
            child: NotifyingListBuilder(
              list: steps,
              itemBuilder: (context, value) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    spacing: 8,
                    children: [
                      Icon(
                        value.passed == null
                            ? Icons.question_mark
                            : value.passed!
                                ? Icons.check
                                : Icons.error,
                        color: value.passed == null
                            ? null
                            : value.passed!
                                ? Colors.green
                                : Colors.red,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            tiamat.Text(value.name),
                            tiamat.Text.labelLow(
                              value.description,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
