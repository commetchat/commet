import 'dart:async';
import 'dart:io';

import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/runners/remote_http/matrix_remote_http_transceiver.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_transport.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:commet/utils/rng.dart';
import 'package:commet/utils/system_processes_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:path/path.dart' as p;

class MatrixUserWidgetRemoteHttpRunner implements MatrixWidgetRunner {
  @override
  MatrixRoom? room;

  @override
  MatrixClient client;

  @override
  late String widgetId;

  late HttpServer server;

  Process? externalBrowserProcess;

  @override
  UserWidgetInfo info;

  @override
  NotifyingList<LogEntry> logs = NotifyingList.empty(growable: true);

  @override
  late WidgetMessageTransport messageTransport;

  @override
  late WidgetEventHandler eventHandler;

  @override
  late WidgetCapabilityManager capabilities;

  late MatrixRemoteHttpWidgetTransceiver tx;

  StreamController _onClosed = StreamController.broadcast();

  @override
  Stream<void> get onClosed => _onClosed.stream;

  bool useInsecureHttp;

  bool allowRemoteConnection;

  MatrixUserWidgetRemoteHttpRunner({
    required this.room,
    required String url,
    required this.widgetId,
    required this.client,
    required HttpServer server,
    required BuildContext context,
    required String hostName,
    required bool launchBrowser,
    required this.info,
    required this.useInsecureHttp,
    required this.allowRemoteConnection,
  }) {
    this.server = server;
    final String secret = RandomUtils.getRandomString(50); // "secret_password";

    tx = MatrixRemoteHttpWidgetTransceiver(
        secret: secret,
        widgetUrl: url,
        hostIp: hostName,
        info: info,
        server: server,
        allowRemoteConnection: allowRemoteConnection,
        useHttps: useInsecureHttp == false,
        onClientConnected: handleInitialConnection);

    messageTransport = MatrixWidgetTransport(tx);

    eventHandler = MatrixWidgetMessageHandler(runner: this);
    capabilities =
        MatrixWidgetCapabilitiesManager(runner: this, context: context);

    if (launchBrowser) {
      var url = Uri(
          scheme: "http",
          host: hostName,
          port: server.port,
          queryParameters: {"token": secret});

      Log.i("Launching browser with url: $url");

      launchExternalBrowser(url);
    } else {
      showConnectionInfo(secret, hostName, context);
    }
  }

  void launchExternalBrowser(Uri url) async {
    ErrorUtils.tryRun(
      navigator.currentContext!,
      () async {
        var tempDir = await getTemporaryDirectory();
        var temp = p.join(tempDir.path, "chat.commet.app", "widget_runner");

        Log.i("Launching chrome with temp location: $temp");

        var knownChromiumBrowsers = ["chromium", "google-chrome"];

        String? selectedBrowser;
        for (var s in knownChromiumBrowsers) {
          Log.i("Looking for browser: ${s}");
          var result = await SystemProcessesUtils.runSubprocess("which", [s]);

          if (result.exitCode == 0) {
            selectedBrowser = s;
            break;
          }

          Log.i("Which result: ${result.exitCode}");
        }

        if (selectedBrowser == null) {
          throw Exception(
              "Could not find any installed chromium browser to run widget");
        }

        var command = selectedBrowser;
        var args = [
          '--app=${url.toString()}',
          '--no-first-run',
          '--no-default-browser-check',
          '--disable-background-networking',
          '--disable-component-update',
          '--user-data-dir=${temp}'
        ];

        if(BuildConfig.IS_FLATPAK) {
          if(PlatformUtils.isDisplayServer(DisplayServer.Wayland)) {
            args = [
              "--ozone-platform=wayland",
              ...args
            ];
          }
        }

        SystemProcessesUtils.spawnSubprocess(command, args).then((process) {
          externalBrowserProcess = process;

          process.exitCode.then((code) {
            Log.i("Browser process terminated with code: $code");

            dispose();
          });
        });
      },
      onError: () async {
        dispose();
      },
    );
  }

  @override
  Future<void> dispose() async {
    await server.close(force: true);
    _onClosed.add(null);
    externalBrowserProcess?.kill(ProcessSignal.sigsegv);
  }

  void handleInitialConnection() async {
    await Future.delayed(Duration(seconds: 2));

    Log.i("Client connected!");
  }

  void showConnectionInfo(
      String secret, String hostName, BuildContext context) async {
    Log.i("Current IP: $hostName");

    var url = Uri(
        scheme: useInsecureHttp ? "http" : "https",
        host: hostName,
        port: server.port,
        queryParameters: {"token": secret});

    Log.i("Url: ${url.toString()}");

    AdaptiveDialog.show(
      context,
      builder: (context) {
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(8),
              child: SizedBox(
                  height: 300,
                  width: 300,
                  child: PrettyQrView.data(
                    data: url.toString(),
                    errorCorrectLevel: QrErrorCorrectLevel.H,
                    decoration: const PrettyQrDecoration(
                        image: const PrettyQrDecorationImage(
                          scale: 0.20,
                          padding: EdgeInsetsGeometry.all(40),
                          filterQuality: FilterQuality.medium,
                          image: AssetImage(
                              'assets/images/app_icon/app_icon_transparent_cropped.png'),
                        ),
                        quietZone: PrettyQrQuietZone.standard,
                        shape: PrettyQrSmoothSymbol(color: Colors.white),
                        background: Colors.black),
                  )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
              child: SizedBox(
                height: 30,
                child: tiamat.TextButton(
                  "Copy Link",
                  icon: Icons.copy,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: url.toString()));
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
