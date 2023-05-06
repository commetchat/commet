import 'package:commet/cache/cached_file.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/emoji/emoji_pack.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  const LoadingPage({required this.clientManager, super.key});
  final ClientManager clientManager;
  @override
  State<LoadingPage> createState() => LoadingPageState();
}

class LoadingPageState extends State<LoadingPage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    load(widget.clientManager);
  }

  Future<bool> load(ClientManager clientManager) async {
    var adapter = CachedFileAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }

    await fileCache.init();
    await EmojiPack.defaults();

    if (BuildConfig.LINUX) {
      Hive.init(await AppConfig.getDatabasePath());
    } else {
      await Hive.initFlutter(await AppConfig.getDatabasePath());
    }
    await MatrixClient.loadFromDB(clientManager);

    //dont let simulated client contribute to logged in status
    bool isLoggedIn = clientManager.isLoggedIn();

    if (BuildConfig.DEBUG) {
      await SimulatedClient.loadFromDB(clientManager);
    }

    setState(() {
      isLoading = false;
    });

    if (context.mounted) {
      NavigationUtils.navigateTo(
          context,
          isLoggedIn
              ? ChatPage(clientManager: clientManager)
              : initialLoginPage());
    }
    return true;
  }

  LoginPage initialLoginPage() {
    return LoginPage(onSuccess: (_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) =>
                ChatPage(clientManager: Provider.of<ClientManager>(context))),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoadingPageView(state: this);
  }
}
