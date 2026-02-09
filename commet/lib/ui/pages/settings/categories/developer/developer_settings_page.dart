import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/diagnostic/diagnostics.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:commet/ui/pages/developer/benchmarks/timeline_viewer_benchmark.dart';
import 'package:commet/ui/pages/settings/categories/app/general_settings_page.dart';
import 'package:commet/ui/pages/settings/categories/developer/cumulative_diagnostics_widget.dart';
import 'package:commet/utils/background_tasks/background_task_manager.dart';
import 'package:commet/utils/background_tasks/mock_tasks.dart';
import 'package:commet/utils/system_processes_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:tiamat/atoms/tile.dart';
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
      benchmarks(),
      windowSize(),
      notificationTests(),
      rendering(),
      error(),
      if (PlatformUtils.isAndroid) shortcuts(),
      backgroundTasks(),
      dumpDatabases(),
      executeShellCommand(),
      tiamat.Panel(
        header: "Other Settings",
        mode: TileType.surfaceContainerLow,
        child: Column(
          children: [
            if (!BuildConfig.MOBILE)
              GeneralSettingsPageState.settingToggle(
                  preferences.disableTextCursorManagement, onChanged: (value) {
                preferences
                    .setdisableTextCursorManagement(value)
                    .then((_) => setState(() {}));
              },
                  title: "Disable Text Cursor Management",
                  description:
                      "As part of the implementaton for the rich text editor, we sometimes have to make automated changes to the text cursor. This disables that"),
          ],
        ),
      )
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
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        collapsedBackgroundColor:
            Theme.of(context).colorScheme.surfaceContainerLow,
        children: [
          Diagnostics.general,
          Diagnostics.initialLoadDatabaseDiagnostics,
          Diagnostics.postLoadDatabaseDiagnostics,
        ].map((e) => CumulativeDiagnosticsWidget(diagnostics: e)).toList());
  }

  Widget rendering() {
    return ExpansionTile(
        title: const tiamat.Text.labelEmphasised("Rendering"),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        collapsedBackgroundColor:
            Theme.of(context).colorScheme.surfaceContainerLow,
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

  Widget benchmarks() {
    return ExpansionTile(
        title: const tiamat.Text.labelEmphasised("Benchmarks"),
        initiallyExpanded: false,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        collapsedBackgroundColor:
            Theme.of(context).colorScheme.surfaceContainerLow,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              tiamat.Button(
                text: "Timeline Viewer",
                onTap: () => NavigationUtils.navigateTo(
                    context, const BenchmarkTimelineViewer()),
              )
            ],
          ),
        ]);
  }

  Widget windowSize() {
    return ExpansionTile(
        title: const tiamat.Text.labelEmphasised("Window Size"),
        initiallyExpanded: false,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        collapsedBackgroundColor:
            Theme.of(context).colorScheme.surfaceContainerLow,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              tiamat.Button(
                text: "Maximize",
                onTap: () => windowManager.maximize(),
              ),
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
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        collapsedBackgroundColor:
            Theme.of(context).colorScheme.surfaceContainerLow,
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
            tiamat.Button(
              text: "Call Notification",
              onTap: () async {
                if (!BuildConfig.ANDROID) {
                  clientManager?.callManager.startRingtone();
                }

                var client = clientManager!.clients.first;
                var room = client.rooms.first;
                var user = client.self!;
                NotificationManager.notify(CallNotificationContent(
                  title: "Incoming Call!",
                  senderImage: user.avatar,
                  senderId: user.identifier,
                  roomName: room.displayName,
                  roomId: room.identifier,
                  senderName: user.displayName,
                  senderImageId: "fake_call_avatar_id",
                  roomImage: await room.getShortcutImage(),
                  content: "Test Call Notification",
                  clientId: client.identifier,
                  callId: "fake_call_id",
                  isDirectMessage: true,
                ));
              },
            ),
          ])
        ]);
  }

  Widget shortcuts() {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Shortcuts"),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
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
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
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
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
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

  Widget executeShellCommand() {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Dangerous"),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          tiamat.Button(
            text: "Get Process List",
            onTap: () async {
              var list = await SystemProcessesUtils.getProcessList();
              AdaptiveDialog.show(
                context,
                builder: (context) {
                  return Codeblock(
                      text: list
                          .map((i) =>
                              "[${i.processId}] = ${i.command}  ${i.args}")
                          .join("\n"));
                },
              );
            },
          ),
          tiamat.Button(
              text: "Execute Shell Command",
              onTap: () async {
                var text = await AdaptiveDialog.textPrompt(context,
                    title: "Execute Shell Command");
                if (text != null) {
                  var command = text.split(" ");
                  var exe = command.first;
                  var args = command.sublist(1);

                  var process = await Process.start(exe, args);

                  AdaptiveDialog.show(context,
                      builder: (context) => ProcessOutputViewer(process));
                }
              }),
        ])
      ],
    );
  }

  Widget dumpDatabases() {
    return ExpansionTile(
      title: const tiamat.Text.labelEmphasised("Dump Databases"),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
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

class ProcessOutputViewer extends StatefulWidget {
  const ProcessOutputViewer(this.process, {super.key});
  final Process process;

  @override
  State<ProcessOutputViewer> createState() => _ProcessOutputViewerState();
}

class _ProcessOutputViewerState extends State<ProcessOutputViewer> {
  String stdOut = "";
  String stdError = "";

  late List<StreamSubscription> subs;

  @override
  void initState() {
    super.initState();

    subs = [
      widget.process.stdout.transform(utf8.decoder).listen(onStdout),
      widget.process.stderr.transform(utf8.decoder).listen(onStderr),
    ];
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }

    widget.process.kill();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1000,
      child: SingleChildScrollView(
        child: Codeblock(
          text: stdOut,
          clipboardText: stdOut,
          language: "stdout",
        ),
      ),
    );
  }

  void onStderr(String event) {
    setState(() {
      stdError += event;
    });
  }

  void onStdout(String event) {
    setState(() {
      stdOut += event;
    });
  }
}
