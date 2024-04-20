import 'dart:async';

import 'package:commet/cache/file_cache.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/config/preferences.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/diagnostic/diagnostics.dart';
import 'package:commet/generated/l10n/messages_all_locales.dart';
import 'package:commet/ui/pages/bubble/bubble_page.dart';
import 'package:commet/ui/pages/fatal_error/fatal_error_page.dart';
import 'package:commet/ui/pages/login/login_page.dart';
import 'package:commet/ui/pages/main/main_page.dart';
import 'package:commet/utils/android_intent_helper.dart';
import 'package:commet/utils/custom_uri.dart';
import 'package:commet/utils/background_tasks/background_task_manager.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/scaled_app.dart';
import 'package:commet/utils/shortcuts_manager.dart';
import 'package:commet/utils/window_management.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:receive_intent/receive_intent.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tiamat/config/style/theme_amoled.dart';
import 'package:tiamat/config/style/theme_changer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:tiamat/config/style/theme_light.dart';

final GlobalKey<NavigatorState> navigator = GlobalKey();
FileCache? fileCache;
Preferences preferences = Preferences();
ShortcutsManager shortcutsManager = ShortcutsManager();
BackgroundTaskManager backgroundTaskManager = BackgroundTaskManager();
Diagnostics diagnostics = Diagnostics();
ClientManager? clientManager;

bool isHeadless = false;

Future<void>? loading;

@pragma('vm:entry-point')
void bubble() async {
  ensureBindingInit();
  await initNecessary();
  await initGuiRequirements();

  String? initialRoomId;
  String? initialClientId;

  var intent = await ReceiveIntent.getInitialIntent();

  if (intent?.extra?.containsKey("bubbleExtra") == true) {
    var uri = CustomURI.parse(intent!.extra!["bubbleExtra"]);

    if (uri is OpenRoomURI) {
      initialClientId = uri.clientId;
      initialRoomId = uri.roomId;
    }
  }

  var theme = preferences.theme;
  var initialTheme = {
    AppTheme.dark: ThemeDark.theme,
    AppTheme.light: ThemeLight.theme,
    AppTheme.amoled: ThemeAmoled.theme,
  }[theme];

  runApp(MaterialApp(
      title: 'Commet',
      theme: initialTheme,
      navigatorKey: navigator,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Provider<ClientManager>(
            create: (context) => clientManager!,
            child: child,
          ),
      home: BubblePage(
        clientManager!,
        initialClientId: initialClientId,
        initialRoom: initialRoomId,
      )));
}

void main() async {
  runZonedGuarded(appMain, Log.onError, zoneSpecification: Log.spec);
}

void appMain() async {
  try {
    if (BuildConfig.WEB) {
      var info = await DeviceInfoPlugin().deviceInfo;
      if (info is WebBrowserInfo) {
        Layout.browserInfo = info;
      }
    }

    ensureBindingInit();

    FlutterError.onError = Log.getFlutterErrorReporter(FlutterError.onError);

    isHeadless = PlatformUtils.isAndroid &&
        AppLifecycleState.detached == WidgetsBinding.instance.lifecycleState;

    loading = initNecessary();

    if (isHeadless) {
      WidgetsBinding.instance.addObserver(AppStarter());
      await loading;
      return;
    } else {
      await loading;
    }

    await startGui();
  } catch (error, stacktrace) {
    runApp(FatalErrorPage(error, stacktrace));
  }
}

WidgetsBinding ensureBindingInit() {
  ScaledWidgetsFlutterBinding.ensureInitialized(
    scaleFactor: (deviceSize) {
      return 1;
    },
  );

  return WidgetsFlutterBinding.ensureInitialized();
}

/// Initializes the bare necessities for the app to run in headless mode
Future<void> initNecessary() async {
  sqfliteFfiInit();
  await preferences.init();
  fileCache = FileCache.getFileCacheInstance();

  await Future.wait([
    if (fileCache != null) fileCache!.init(),
    ClientManager.init(),
  ]);

  shortcutsManager.init();
  NotificationManager.init();

  NeedsPostLoginInit.doPostLoginInit();
}

/// Initializes everything that is needed to run in GUI mode
Future<void> initGuiRequirements() async {
  isHeadless = false;

  var locale = PlatformDispatcher.instance.locale;

  MediaKit.ensureInitialized();

  Future.wait([
    WindowManagement.init(),
    UnicodeEmojis.load(),
    initializeMessages(locale.languageCode)
  ]);

  Intl.defaultLocale = locale.languageCode;
}

/// Initializes gui requirements and launches the gui
Future<void> startGui() async {
  String? initialRoomId;
  String? initialClientId;

  initGuiRequirements();

  if (PlatformUtils.isAndroid) {
    enableEdgeToEdge();

    var initialIntent = await ReceiveIntent.getInitialIntent();
    ReceiveIntent.receivedIntentStream.listen((event) {
      var uri = AndroidIntentHelper.getUriFromIntent(event);
      if (uri is OpenRoomURI) {
        EventBus.openRoom.add((uri.roomId, uri.clientId));
      }
    });

    var uri = AndroidIntentHelper.getUriFromIntent(initialIntent);

    if (uri is OpenRoomURI) {
      initialClientId = uri.clientId;
      initialRoomId = uri.roomId;
    }
  }

  double scale = preferences.appScale;

  ScaledWidgetsFlutterBinding.instance.scaleFactor = (deviceSize) {
    return scale;
  };

  runApp(App(
    clientManager: clientManager!,
    initialTheme: preferences.theme,
    initialClientId: initialClientId,
    initialRoom: initialRoomId,
  ));
}

void enableEdgeToEdge() {
  SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge); // Enable Edge-to-Edge on Android 10+
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor:
        Colors.transparent, // Setting a transparent navigation bar color
    systemNavigationBarContrastEnforced: true, // Default
    systemNavigationBarIconBrightness:
        [AppTheme.amoled, AppTheme.dark].contains(preferences.theme)
            ? Brightness.light
            : Brightness.dark, // This defines the color of the scrim
  ));
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
        initialTheme: {
          AppTheme.dark: ThemeDark.theme,
          AppTheme.light: ThemeLight.theme,
          AppTheme.amoled: ThemeAmoled.theme,
        }[initialTheme]!,
        materialAppBuilder: (context, theme) {
          return MaterialApp(
            title: 'Commet',
            theme: theme,
            navigatorKey: navigator,
            localizationsDelegates: T.localizationsDelegates,
            builder: (context, child) => Provider<ClientManager>(
              create: (context) => clientManager,
              child: child,
            ),
            supportedLocales: T.supportedLocales,
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
  void initState() {
    super.initState();
  }

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

class AppStarter with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached) return;
    if (loading != null) {
      await loading;
    }

    if (isHeadless) {
      startGui();
    }

    super.didChangeAppLifecycleState(state);
  }
}
