// Abstract Space-level soundboard catalog seam (a real SpaceComponent so
// it participates in ComponentRegistry + space.getComponent<T>()).
import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/soundboard/soundboard_emoji.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/client/components/space_component.dart';

abstract class SpaceSoundboardComponent<R extends Client, T extends Space>
    extends SpaceComponent<R, T> {
  static const String stateEventType = 'chat.commet.soundboard.sound';

  SpaceSoundboardComponent(super.client, super.space);

  List<SoundboardSound> get sounds;
  SoundboardSound? getById(String soundId);
  Stream<void> get onChanged;

  /// True if local user may add/edit/remove (power levels, not just hidden UI).
  bool get canManage;

  Future<SoundboardSound> addSound({
    required String name,
    required SoundboardEmoji emoji,
    required String mediaUri,
    required String mimeType,
    required int durationMs,
    required double normalizedGain,
    double volume = 1.0,
    String? sourceUrl,
  });

  Future<SoundboardSound> updateSound(
    String soundId, {
    String? name,
    SoundboardEmoji? emoji,
    double? volume,
  });

  Future<void> removeSound(String soundId);
}
