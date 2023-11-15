import 'dart:io';

import 'package:commet/cache/file_cache.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/preferences.dart';
import 'package:commet/diagnostic/diagnostics.dart';
import 'package:commet/ui/pages/login/login_page.dart';
import 'package:commet/ui/pages/main/main_page.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:commet/utils/notification/notification_manager.dart';
import 'package:commet/utils/scaled_app.dart';
import 'package:commet/utils/shortcuts_manager.dart';
import 'package:commet/utils/window_management.dart';

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:media_kit/media_kit.dart';

import 'package:provider/provider.dart';
import 'package:receive_intent/receive_intent.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tiamat/config/style/theme_changer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:tiamat/config/style/theme_light.dart';

import 'cache/cached_file.dart';
import 'client/simulated/simulated_client.dart';
import 'config/app_config.dart';

final GlobalKey<NavigatorState> navigator = GlobalKey();
FileCacheInstance fileCache = FileCacheInstance();
Preferences preferences = Preferences();
NotificationManager notificationManager = NotificationManager();
ShortcutsManager shortcutsManager = ShortcutsManager();
Diagnostics diagnostics = Diagnostics();
ClientManager? clientManager;

@pragma('vm:entry-point')
void bubble() {
  main();
}

void main() async {
  String? initialRoomId;
  String? initialClientId;

  ScaledWidgetsFlutterBinding.ensureInitialized(
    scaleFactor: (deviceSize) {
      return 1;
    },
  );

  WidgetsFlutterBinding.ensureInitialized();

  await preferences.init();
  notificationManager.init();
  shortcutsManager.init();
  if (Platform.isAndroid) {
    databaseFactory = databaseFactorySqflitePlugin;
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  clientManager =
      await diagnostics.timeAsync("App initialization", () => initApp());

  double scale = preferences.appScale;
  var theme = preferences.theme;

  ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
    return scale;
  };

  if (Platform.isAndroid) {
    var intent = await ReceiveIntent.getInitialIntent();
    if (intent?.extra?.containsKey("flutter_shortcuts") == true) {
      var uri = Uri.parse(intent!.extra!["flutter_shortcuts"]);
      switch (uri.authority) {
        case "open_room":
          initialRoomId = uri.queryParameters["room_id"];
          initialClientId = uri.queryParameters["client_id"];
          break;
        default:
      }
    }
  }

  runApp(App(
    clientManager: clientManager!,
    initialTheme: theme,
    initialClientId: initialClientId,
    initialRoom: initialRoomId,
  ));
}

Future<ClientManager> initApp() async {
  var adapter = CachedFileAdapter();

  MediaKit.ensureInitialized();

  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }

  var dbPath = await AppConfig.getDatabasePath();

  await Future.wait([
    diagnostics.timeAsync(
      "Cleaning file cache",
      () => fileCache.init().then((value) => fileCache.clean()),
    ),
    diagnostics.timeAsync("Loading default emoji", () => UnicodeEmojis.load()),
    notificationManager.init(),
    WindowManagement.init(),
    if (!BuildConfig.LINUX) Hive.initFlutter(dbPath),
  ]);

  if (BuildConfig.LINUX) {
    Hive.init(dbPath);
  }

  final clientManager = ClientManager();

  await diagnostics.timeAsync("Loading clients", () async {
    await Future.wait([
      MatrixClient.loadFromDB(clientManager),
      if (BuildConfig.DEBUG) SimulatedClient.loadFromDB(clientManager),
    ]);
  });

  return clientManager;
}

class App extends StatelessWidget {
  const App(
      {Key? key,
      required this.clientManager,
      this.initialTheme = AppTheme.dark,
      this.initialRoom,
      this.initialClientId})
      : super(key: key);
  final AppTheme initialTheme;
  final ClientManager clientManager;

  final String? initialRoom;
  final String? initialClientId;

  @override
  Widget build(BuildContext context) {
    return ThemeChanger(
        initialTheme:
            initialTheme == AppTheme.dark ? ThemeDark.theme : ThemeLight.theme,
        materialAppBuilder: (context, theme) {
          return MaterialApp(
            title: 'Commet',
            theme: theme,
            navigatorKey: navigator,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => Provider<ClientManager>(
              create: (context) => clientManager,
              child: child,
            ),
            home: AppView(
              clientManager: clientManager,
              initialClientId: initialClientId,
              initialRoom: initialRoom,
            ),
          );
        });
  }
}

class AppView extends StatefulWidget {
  const AppView(
      {required this.clientManager,
      super.key,
      this.initialClientId,
      this.initialRoom});
  final ClientManager clientManager;
  final String? initialRoom;
  final String? initialClientId;

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  @override
  Widget build(BuildContext context) {
    return widget.clientManager.isLoggedIn()
        ? MainPage(
            widget.clientManager,
            initialClientId: widget.initialClientId,
            initialRoom: widget.initialRoom,
          )
        : LoginPage(onSuccess: (_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => MainPage(widget.clientManager)),
              (route) => false,
            );
          });
  }
}
