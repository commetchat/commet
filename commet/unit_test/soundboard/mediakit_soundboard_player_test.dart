import 'package:commet/client/matrix/components/soundboard/mediakit_soundboard_player.dart';
import 'package:test/test.dart';

void main() {
  test('player volume is on media_kit\'s 0..100 scale', () {
    // 0.8 here once meant mpv volume 0.8 of 100: inaudible.
    expect(MediaKitSoundboardPlayer.mpvVolume(0.8, 1.0), closeTo(80, 1e-9));
    expect(MediaKitSoundboardPlayer.mpvVolume(0.8, 0.5), closeTo(40, 1e-9));
    expect(MediaKitSoundboardPlayer.mpvVolume(0, 1.0), 0);
  });

  test('player volume never boosts past unchanged', () {
    expect(MediaKitSoundboardPlayer.mpvVolume(1.5, 1.0), 100);
    expect(MediaKitSoundboardPlayer.mpvVolume(1.0, 4.0), 100);
  });
}
