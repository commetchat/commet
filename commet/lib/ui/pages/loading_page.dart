import 'package:commet/client/client_manager.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/simulated/simulated_client.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:commet/ui/pages/chat/chat_page.dart';
import 'package:commet/ui/pages/login_page.dart';
import 'package:flutter/material.dart';
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

    if (context.mounted) {
      NavigationUtils.navigateTo(context, isLoggedIn ? const ChatPage() : const LoginPage());
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: SizedBox(
            width: s(60),
            height: s(60),
            child: const CircularProgressIndicator(),
          ),
        ),
        Text(T.of(context).loading)
      ],
    );
  }
}
