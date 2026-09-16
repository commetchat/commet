import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/client/matrix/components/soundboard/mediakit_soundboard_player.dart';
import 'package:test/test.dart';

void main() {
  test('player volume is on media_kit\'s 0..100 scale', () {
    // 0.8 here once meant mpv volume 0.8 of 100: inaudible.
    expect(MediaKitSoundboardPlayer.mpvVolume(0.8, 1.0), closeTo(80, 1e-9));
    expect(MediaKitSoundboardPlayer.mpvVolume(0.8, 0.5), closeTo(40, 1e-9));
    expect(MediaKitSoundboardPlayer.mpvVolume(0, 1.0), 0);
  });

  test('admin volume scales one sound on top of normalization', () {
    const quiet = SoundboardSound(
      soundId: 's1',
      name: 'Airhorn',
      emoji: '📢',
      mediaUri: 'mxc://x/s1',
      mimeType: 'audio/mpeg',
      durationMs: 2000,
      normalizedGain: 0.8,
      volume: 0.5,
    );
    // normalizedGain * adminVolume * userVolume = 0.8 * 0.5 * 1.0
    expect(
        MediaKitSoundboardPlayer.mpvVolume(1.0, quiet.gain), closeTo(40, 1e-9));
  });

  test('player volume never boosts past unchanged', () {
    expect(MediaKitSoundboardPlayer.mpvVolume(1.5, 1.0), 100);
    expect(MediaKitSoundboardPlayer.mpvVolume(1.0, 4.0), 100);
  });
}
