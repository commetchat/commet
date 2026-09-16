import 'package:media_kit/media_kit.dart';

Future<void> raiseMpvVolumeMax(Player player, double max) async {
  final native = player.platform;
  if (native is NativePlayer) {
    await native.setProperty('volume-max', max.toString());
  }
}
