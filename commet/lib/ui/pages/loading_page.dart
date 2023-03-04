import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/simulated/simulated_client.dart';
import 'package:commet/ui/pages/chat_page.dart';
import 'package:commet/ui/pages/desktop_chat_page.dart';
import 'package:commet/ui/pages/login_page.dart';
import 'package:commet/ui/pages/mobile_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:provider/provider.dart';

import '../../config/build_config.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<bool> load() async {
    var client = Provider.of<ClientManager>(context, listen: false);

    await MatrixClient.loadFromDB(client);

    //dont let simulated client contribute to logged in status
    bool isLoggedIn = client.isLoggedIn();

    if (BuildConfig.DEBUG) {
      await SimulatedClient.loadFromDB(client);
    }

    setState(() {
      isLoading = false;
    });

    Navigator.push(
        context,
        PageRouteBuilder(
            pageBuilder: (_, __, ___) => isLoggedIn ? ChatPage() : LoginPage(),
            transitionDuration: Duration(milliseconds: 500),
            transitionsBuilder: (_, animation, __, child) => SlideTransition(
                child: child,
                position: Tween<Offset>(
                  begin: const Offset(0, 1.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)))));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 60,
        height: 60,
        child: CircularProgressIndicator(),
      ),
    );
  }
}
