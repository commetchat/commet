import 'package:commet/cache/file_cache.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/config/preferences.dart';
import 'package:commet/ui/pages/loading/loading_page.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:scaled_app/scaled_app.dart';
import 'package:tiamat/config/style/theme_changer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:tiamat/config/style/theme_glass.dart';
import 'package:tiamat/config/style/theme_light.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import 'generated/l10n.dart';

final GlobalKey<NavigatorState> navigator = GlobalKey();
FileCacheInstance fileCache = FileCacheInstance();
Preferences preferences = Preferences();

void main() async {
  await preferences.init();
  double scale = preferences.getAppScale();
  ScaledWidgetsFlutterBinding.ensureInitialized(
    scaleFactor: (deviceSize) {
      return scale;
    },
  );
  var theme = preferences.getTheme();

  runApp(App(
    initialTheme: theme,
  ));
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
  App({Key? key, this.initialTheme = AppTheme.dark}) : super(key: key);
  final AppTheme initialTheme;
  final clientManager = ClientManager();

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
            home: LoadingPage(
              clientManager: clientManager,
            ),
          );
        });
  }
}
