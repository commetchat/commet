import 'package:commet/client/client_manager.dart';
import 'package:commet/config/style/theme_changer.dart';
import 'package:commet/ui/pages/desktop_chat_page.dart';
import 'package:commet/ui/pages/login_page.dart';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'client/client.dart';
import 'client/matrix/matrix_client.dart';
import 'client/simulated/simulated_client.dart';
import 'config/style/theme_dark.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(App());
}

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);
  final clientManager = ClientManager();

  @override
  Widget build(BuildContext context) {
    /* return ThemeChanger(
        initialTheme: ThemeDark().theme,
        materialAppBuilder: ((context, theme) {
          return MaterialApp(
            title: 'Commet',
            theme: theme,
            builder: (context, child) => Provider<ClientManager>(
              create: (context) => client,
              child: child,
            ),
            home:
                client.isLoggedIn() ? const RoomListPage() : const LoginPage(),
          );
        }));
      */

    return MaterialApp(
        title: 'Commet',
        theme: ThemeDark().theme,
        builder: (context, child) => Provider<ClientManager>(
              create: (context) => clientManager,
              child: child,
            ),
        home: LoginPage() //client.isLoggedIn() ? const DesktopChatPage() : const LoginPage(),
        );
  }
}
