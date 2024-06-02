import 'dart:io';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/background_tasks/background_task_manager.dart';
import 'package:commet/utils/background_tasks/mock_tasks.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
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
      rendering(),
      error(),
      if (Platform.isAndroid) shortcuts(),
      backgroundTasks(),
      dumpDatabases()
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

  Widget rendering() {
    return ExpansionTile(
        title: const tiamat.Text.labelEmphasised("Rendering"),
        initiallyExpanded: false,
        backgroundColor:
            Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
        collapsedBackgroundColor:
            Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const tiamat.Text.label("Show repaints"),
                  tiamat.Switch(
                    state: debugRepaintRainbowEnabled,
                    onChanged: (value) {
                      setState(() {
                        debugRepaintRainbowEnabled = value;
                      });
                    },
                  ),
                ],
              )
            ]),
          )
        ]);
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
              NotificationManager.notify(MessageNotificationContent(
                senderName: user.displayName,
                senderImage: user.avatar,
                senderId: user.identifier,
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

  Widget shortcuts() {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Shortcuts"),
      backgroundColor: Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      collapsedBackgroundColor:
          Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          tiamat.Button(
            text: "Clear Shortcuts",
            onTap: () async {
              await shortcutsManager.clearAllShortcuts();
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
          tiamat.Button(
              text: "Async task with crash",
              onTap: () => backgroundTaskManager.addTask(AsyncTask(() async {
                    await Future.delayed(const Duration(seconds: 5));
                    throw Exception("This background task failed!");
                  }, "Async task"))),
        ])
      ],
    );
  }

  Widget error() {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Error"),
      backgroundColor: Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      collapsedBackgroundColor:
          Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          tiamat.Button(
              text: "Throw an error",
              onTap: () {
                // This should also throw an error!
                String? empty;
                empty!.split(" ");
              }),
        ])
      ],
    );
  }

  Widget dumpDatabases() {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Dump Databases"),
      backgroundColor: Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      collapsedBackgroundColor:
          Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          tiamat.Button(
              text: "Dump Databases",
              onTap: () async {
                var folder = await FilePicker.platform.getDirectoryPath();
                var dbDir = Directory(await AppConfig.getDatabasePath());

                var files = await dbDir
                    .list(recursive: true)
                    .where((event) => event is File)
                    .toList();

                for (var file in files) {
                  var name = p.basename(file.path);
                  var dirname = p.basename(p.dirname(file.path));

                  var newFolder = Directory(p.join(folder!, dirname));
                  if (!await newFolder.exists()) {
                    await newFolder.create(recursive: true);
                  }

                  var newFile = p.join(folder, dirname, name);
                  (file as File).copy(newFile);
                }
              }),
        ])
      ],
    );
  }
}
