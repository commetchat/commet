import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:provider/provider.dart';

import '../../../client/client_manager.dart';
import '../../../client/matrix/matrix_client.dart';
import '../../../client/simulated/simulated_client.dart';
import '../../../config/build_config.dart';
import '../../navigation/navigation_utils.dart';
import '../chat/chat_page.dart';
import '../login/login_page.dart';
import 'loading_page_view.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => LoadingPageState();
}

class LoadingPageState extends State<LoadingPage> {
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
    return LoadingPageView(state: this);
  }
}
