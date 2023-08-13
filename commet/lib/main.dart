import 'package:commet/cache/file_cache.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/preferences.dart';
import 'package:commet/diagnostic/diagnostics.dart';
import 'package:commet/ui/pages/chat/chat_page.dart';
import 'package:commet/ui/pages/login/login_page.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:commet/utils/notification/notification_manager.dart';
import 'package:commet/utils/notification/notifier.dart';
import 'package:commet/utils/window_management.dart';

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:media_kit/media_kit.dart';

import 'package:provider/provider.dart';
import 'package:scaled_app/scaled_app.dart';
import 'package:tiamat/config/style/theme_changer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:tiamat/config/style/theme_glass.dart';
import 'package:tiamat/config/style/theme_light.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import 'cache/cached_file.dart';
import 'client/simulated/simulated_client.dart';
import 'config/app_config.dart';
import 'generated/l10n.dart';

final GlobalKey<NavigatorState> navigator = GlobalKey();
FileCacheInstance fileCache = FileCacheInstance();
Preferences preferences = Preferences();
NotificationManager notificationManager = NotificationManager();
Diagnostics diagnostics = Diagnostics();
ClientManager? clientManager;

void main() async {
  ScaledWidgetsFlutterBinding.ensureInitialized(
    scaleFactor: (deviceSize) {
      return 1;
    },
  );

  WidgetsFlutterBinding.ensureInitialized();

  await preferences.init();

  clientManager =
      await diagnostics.timeAsync("App initialization", () => initApp());

  double scale = preferences.appScale;
  var theme = preferences.theme;

  ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
    return scale;
  };

  runApp(App(
    clientManager: clientManager!,
    initialTheme: theme,
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
    Notifier.init(),
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

@WidgetbookTheme(name: 'Dark')
ThemeData commetDarkTheme() => ThemeDark.theme;

@WidgetbookTheme(name: 'Light')
ThemeData commetLightTheme() => ThemeLight.theme;

@WidgetbookTheme(name: 'Glass')
ThemeData commetGlassTheme() => ThemeGlass.theme;

@WidgetbookApp.material(name: 'Commet', devices: [
  Apple.iPhone12,
  Apple.macBook13Inch,
  Device.desktop(
      name: "720p",
      resolution: Resolution(
          nativeSize: DeviceSize(width: 1280, height: 720), scaleFactor: 1))
])
class App extends StatelessWidget {
  const App(
      {Key? key,
      required this.clientManager,
      this.initialTheme = AppTheme.dark})
      : super(key: key);
  final AppTheme initialTheme;
  final ClientManager clientManager;

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
              T.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: T.delegate.supportedLocales,
            builder: (context, child) => Provider<ClientManager>(
              create: (context) => clientManager,
              child: child,
            ),
            home: AppView(
              clientManager: clientManager,
            ),
          );
        });
  }
}

class AppView extends StatefulWidget {
  const AppView({required this.clientManager, super.key});
  final ClientManager clientManager;

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  @override
  Widget build(BuildContext context) {
    return widget.clientManager.isLoggedIn()
        ? ChatPage(clientManager: widget.clientManager)
        : LoginPage(onSuccess: (_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (_) =>
                      ChatPage(clientManager: widget.clientManager)),
              (route) => false,
            );
          });
  }
}
