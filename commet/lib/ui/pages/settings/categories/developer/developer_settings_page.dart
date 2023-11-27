import 'package:commet/main.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:commet/utils/background_tasks/mock_tasks.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:window_manager/window_manager.dart';

class DeveloperSettingsPage extends StatefulWidget {
  const DeveloperSettingsPage({super.key});

  @override
  State<DeveloperSettingsPage> createState() => _DeveloperSettingsPageState();
}

class _DeveloperSettingsPageState extends State<DeveloperSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
      performance(),
      windowSize(),
      notificationTests(),
      backgroundTasks(),
    ].map<Widget>((e) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: e),
      );
    }).toList());
  }

  Widget performance() {
    return ExpansionTile(
        title: const tiamat.Text.labelEmphasised("Performance"),
        initiallyExpanded: false,
        backgroundColor:
            Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
        collapsedBackgroundColor:
            Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
        children: diagnostics.results
            .map((e) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: tiamat.Text.labelEmphasised(e.name)),
                      tiamat.Text.label("${e.time.inMilliseconds}ms")
                    ],
                  ),
                ))
            .toList());
  }

  Widget windowSize() {
    return ExpansionTile(
        title: const tiamat.Text.labelEmphasised("Window Size"),
        initiallyExpanded: false,
        backgroundColor:
            Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
        collapsedBackgroundColor:
            Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              tiamat.Button(
                text: "1280x720",
                onTap: () => windowManager.setSize(const Size(1280, 720)),
              ),
              tiamat.Button(
                text: "1920x1080",
                onTap: () => windowManager.setSize(const Size(1920, 1080)),
              ),
              tiamat.Button(
                text: "2560x1440",
                onTap: () => windowManager.setSize(const Size(2560, 1440)),
              ),
              tiamat.Button(
                text: "3840x2160",
                onTap: () => windowManager.setSize(const Size(3840, 2160)),
              ),
              tiamat.Button(
                text: "1170x2532 (iPhone 12 Pro)",
                onTap: () => windowManager.setSize(const Size(1170, 2532)),
              ),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              tiamat.Button(
                text: "1:1",
                onTap: () => setAspectRatio(1),
              ),
              tiamat.Button(
                text: "16:9",
                onTap: () => setAspectRatio(16 / 9),
              ),
            ],
          )
        ]);
  }

  void setAspectRatio(double ratio) async {
    var size = await windowManager.getSize();
    var newWidth = size.height * ratio;
    await windowManager.setSize(Size(newWidth, size.height));
  }

  Widget notificationTests() {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Notifications"),
      backgroundColor: Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      collapsedBackgroundColor:
          Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          tiamat.Button(
            text: "Message Notification",
            onTap: () async {
              var client = clientManager!.clients.first;
              var room = client.rooms.first;
              var user = client.self!;
              notificationManager.notify(MessageNotificationContent(
                senderName: user.displayName,
                senderImage: user.avatar,
                roomName: room.displayName,
                roomId: room.identifier,
                roomImage: await room.getShortcutImage(),
                content: "Test Message!",
                clientId: client.identifier,
                eventId: "fake_event_id",
                isDirectMessage: true,
              ));
            },
          ),
        ])
      ],
    );
  }

  Widget backgroundTasks() {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Background Tasks"),
      backgroundColor: Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      collapsedBackgroundColor:
          Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          tiamat.Button(
              text: "With progress",
              onTap: () => backgroundTaskManager
                  .addTask(FakeBackgroundTaskWithProgress())),
          tiamat.Button(
              text: "Indeterminate",
              onTap: () => backgroundTaskManager.addTask(FakeBackgroundTask())),
        ])
      ],
    );
  }
}
