import 'package:commet/client/client_manager.dart';
import 'package:commet/config/style/theme_changer.dart';
import 'package:commet/config/style/theme_glass.dart';
import 'package:commet/config/style/theme_light.dart';
import 'package:commet/ui/pages/chat/desktop_chat_page.dart';
import 'package:commet/ui/pages/loading_page.dart';
import 'package:commet/ui/pages/login_page.dart';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'client/client.dart';
import 'client/matrix/matrix_client.dart';
import 'client/simulated/simulated_client.dart';
import 'config/build_config.dart';
import 'config/style/theme_dark.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

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
            home: LoadingPage(),
          );
        });
  }
}
