import 'dart:async';
import 'dart:io';

import 'package:commet/cache/file_cache.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/push_notification/android/unified_push_notifier.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/global_config.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/config/preferences.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/diagnostic/diagnostics.dart';
import 'package:commet/generated/intl/messages_all.dart';
import 'package:commet/single_instance.dart';
import 'package:commet/ui/pages/bubble/bubble_page.dart';
import 'package:commet/ui/pages/fatal_error/fatal_error_page.dart';
import 'package:commet/ui/pages/login/login_page.dart';
import 'package:commet/ui/pages/main/main_page.dart';
import 'package:commet/ui/pages/setup/menus/check_for_updates.dart';
import 'package:commet/utils/android_intent_helper.dart';
import 'package:commet/utils/custom_uri.dart';
import 'package:commet/utils/background_tasks/background_task_manager.dart';
import 'package:commet/utils/database/database_server.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/first_time_setup.dart';
import 'package:commet/utils/scaled_app.dart';
import 'package:commet/utils/shortcuts_manager.dart';
import 'package:commet/utils/system_wide_shortcuts/system_wide_shortcuts.dart';
import 'package:commet/utils/update_checker.dart';
import 'package:commet/utils/window_management.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:receive_intent/receive_intent.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tiamat/config/style/theme_changer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:window_manager/window_manager.dart';

final GlobalKey<NavigatorState> navigator = GlobalKey();
FileCache? fileCache;
Preferences preferences = Preferences();
ShortcutsManager shortcutsManager = ShortcutsManager();
BackgroundTaskManager backgroundTaskManager = BackgroundTaskManager();
ClientManager? clientManager;

bool isHeadless = false;

Future<void>? loading;

List<String> commandLineArgs = [];

@pragma('vm:entry-point')
void unifiedPushEntry() async {
  isHeadless = true;
  Log.prefix = "unified-push";
  await WidgetsFlutterBinding.ensureInitialized();
  await preferences.init();
  await UnifiedPushNotifier().init();
}

@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse details) {
  print("Got a background notification response: $details");
}

@pragma('vm:entry-point')
void bubble() async {
  Log.prefix = "bubble";
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

  Log.prefix = "bubble-$initialRoomId";

  var initialTheme = await preferences.resolveTheme();

  runApp(MaterialApp(
      title: 'Commet',
      theme: initialTheme,
      navigatorKey: navigator,
      debugShowCheckedModeBanner: false,
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

void main(List<String> args) async {
  commandLineArgs = args;
  print(args);

  if (runWebViewTitleBarWidget(args)) {
    return;
  }

  if (PlatformUtils.isLinux || PlatformUtils.isWindows) {
    if (await SingleInstance.tryConnectToMainInstance(args)) {
      exit(0);
    } else {
      SingleInstance.becomeMainInstance();
    }
  }

  if (BuildConfig.RELEASE) {
    runZonedGuarded(appMain, Log.onError, zoneSpecification: Log.spec);
  } else {
    appMain();
  }
}

void appMain() async {
  Log.prefix = "main";
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

    SystemWideShortcuts.init();

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
  await initDatabaseServer();

  fileCache = FileCache.getFileCacheInstance();

  await Future.wait([
    if (fileCache != null) fileCache!.init(),
    GlobalConfig.init(),
  ]);

  clientManager = await ClientManager.init();
  Diagnostics.setPostInit();

  shortcutsManager.init();
  NotificationManager.init();

  NeedsPostLoginInit.doPostLoginInit();
}

/// Initializes everything that is needed to run in GUI mode
Future<void> initGuiRequirements() async {
  isHeadless = false;

  MediaKit.ensureInitialized();

  var locale = PlatformDispatcher.instance.locale;

  Future.wait([
    UnicodeEmojis.load(),
    initializeMessages(locale.languageCode),
    initializeDateFormatting(locale.languageCode),
    // initializeMessagesDebug()
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
      Log.i("Received intent: ${initialIntent}");
      var uri = AndroidIntentHelper.getUriFromIntent(event);
      if (uri is OpenRoomURI) {
        EventBus.openRoom.add((uri.roomId, uri.clientId));
      }
    });

    Log.i("Initial intent: ${initialIntent}");

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

  var initialTheme = await preferences.resolveTheme();

  if (preferences.checkForUpdates == null &&
      UpdateChecker.shouldCheckForUpdates) {
    FirstTimeSetup.registerPostLoginSetup(UpdateCheckerSetup());
  }

  runApp(App(
    clientManager: clientManager!,
    initialTheme: initialTheme,
    initialClientId: initialClientId,
    initialRoom: initialRoomId,
  ));

  WindowManagement.init();
}

void enableEdgeToEdge() async {
  var theme = await preferences.resolveTheme();
  SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge); // Enable Edge-to-Edge on Android 10+
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor:
          Colors.transparent, // Setting a transparent navigation bar color
      systemNavigationBarContrastEnforced: true, // Default
      systemNavigationBarIconBrightness: theme.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark));
}

class App extends StatelessWidget {
  const App(
      {super.key,
      required this.clientManager,
      this.initialTheme,
      this.initialRoom,
      this.initialClientId});
  final ThemeData? initialTheme;
  final ClientManager clientManager;

  final String? initialRoom;
  final String? initialClientId;

  @override
  Widget build(BuildContext context) {
    return ThemeChanger(
        shouldFollowSystemTheme: () => preferences.shouldFollowSystemTheme,
        getDarkTheme: () {
          return preferences.resolveTheme(overrideBrightness: Brightness.dark);
        },
        getLightTheme: () {
          return preferences.resolveTheme(overrideBrightness: Brightness.light);
        },
        initialTheme: initialTheme ?? ThemeDark.theme,
        materialAppBuilder: (context, theme) {
          return MaterialApp(
            title: 'Commet',
            theme: theme,
            debugShowCheckedModeBanner: false,
            navigatorKey: navigator,
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
