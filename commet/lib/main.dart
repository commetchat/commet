import 'package:commet/client/client_manager.dart';

import 'package:commet/ui/pages/loading_page.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:scaled_app/scaled_app.dart';
import 'package:tiamat/config/style/theme_changer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tiamat/config/style/theme_dark.dart';

import 'generated/l10n.dart';

void main() async {
  ScaledWidgetsFlutterBinding.ensureInitialized(
    scaleFactor: (deviceSize) {
      return 1;
    },
  );
  runApp(App());
}

final GlobalKey<NavigatorState> navigator = GlobalKey();

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
