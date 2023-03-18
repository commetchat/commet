import 'package:commet/client/client_manager.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/pages/loading/loading_page.dart';
import 'package:dart_vlc/dart_vlc.dart';

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

void main() async {
  ScaledWidgetsFlutterBinding.ensureInitialized(
    scaleFactor: (deviceSize) {
      return 1;
    },
  );

  if (BuildConfig.DESKTOP) DartVLC.initialize();

  runApp(App());
}

final GlobalKey<NavigatorState> navigator = GlobalKey();

@WidgetbookTheme(name: 'Dark')
ThemeData commetDarkTheme() => ThemeDark.theme;

@WidgetbookTheme(name: 'Light')
ThemeData commetLightTheme() => ThemeLight.theme;

@WidgetbookTheme(name: 'Glass')
ThemeData commetGlassTheme() => ThemeGlass.theme;

@WidgetbookApp.material(name: 'Commet', devices: [Apple.iPhone12, Apple.macBook13Inch])
class App extends StatelessWidget {
  App({Key? key}) : super(key: key);
  final clientManager = ClientManager();

  @override
  Widget build(BuildContext context) {
    return ThemeChanger(
        initialTheme: ThemeDark.theme,
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
            home: const LoadingPage(),
          );
        });
  }
}
