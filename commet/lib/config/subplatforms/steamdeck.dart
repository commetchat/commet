import 'dart:ui';

import 'package:commet/config/platform_utils.dart';
import 'package:commet/config/subplatforms/subplatforms.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/system_processes_utils.dart';
import 'package:window_manager/window_manager.dart';

class SteamdeckSubplatform implements Subplatform {
  @override
  Future<void> init() async {
    if (_isGameMode) {
      await windowManager.setSize(Size(1280, 800));
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
