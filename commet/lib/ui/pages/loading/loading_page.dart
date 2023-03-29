import 'package:commet/cache/cached_file.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/emoji/emoji_pack.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

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
    await preferences.init();
    await fileCache.init();
    await EmojiPack.defaults();

    if (BuildConfig.LINUX) {
      Hive.init(await AppConfig.getDatabasePath());
    } else {
      Hive.initFlutter(await AppConfig.getDatabasePath());
    }

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
      NavigationUtils.navigateTo(context, isLoggedIn ? ChatPage(clientManager: client) : const LoginPage());
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return LoadingPageView(state: this);
  }
}
