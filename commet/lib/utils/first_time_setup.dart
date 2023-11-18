import 'package:commet/ui/pages/setup/setup_menu.dart';

class FirstTimeSetup {
  static final List<SetupMenu> _postLogin = List.empty(growable: true);

  static List<SetupMenu> get postLogin => _postLogin;

  static void registerPostLoginSetup(SetupMenu menu) {
    _postLogin.add(menu);
  }
}
