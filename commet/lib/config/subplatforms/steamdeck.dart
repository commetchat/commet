import 'package:commet/config/platform_utils.dart';
import 'package:commet/config/subplatforms/subplatforms.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/system_processes_utils.dart';
import 'package:window_manager/window_manager.dart';

class SteamdeckSubplatform implements Subplatform {
  @override
  Future<void> init() async {
    Log.i(
        "Initializing steamdeck subplatform: ${_isSteamDeck} is gamemode: ${_isGameMode}");

    if (_isGameMode) {
      await windowManager.setFullScreen(true);
      ensureFullscreen();
    }
  }

  Future<void> ensureFullscreen() async {
    for (int i = 0; i < 10; i++) {
      if (await windowManager.isFullScreen()) {
        return;
      }

      Log.i("Window is still not fullscreen, waiting and trying again");

      await Future.delayed(Duration(seconds: 1));
      await windowManager.setFullScreen(true);
    }
  }

  @override
  String get name => _isGameMode ? "steamdeck_gamemode" : "steamdeck_desktop";

  static bool _isSteamDeck = false;

  static bool _isGameMode = false;

  static Future<bool> isSteamdeck() async {
    if (!PlatformUtils.isLinux) {
      return false;
    }

    var processes = await SystemProcessesUtils.getProcessList();

    var steamProceses = processes.where((i) => i.command.endsWith("/steam"));

    _isSteamDeck = steamProceses.any((i) => i.args.contains("-steamdeck"));

    _isGameMode =
        _isSteamDeck && steamProceses.any((i) => i.args.contains("-gamepadui"));

    Log.i(
        "Is running on steamdeck: ${_isSteamDeck} is gamemode: ${_isGameMode}");

    return _isSteamDeck;
  }
}
