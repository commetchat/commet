// Matrix adapter: one state event per sound.
//
// Type: `chat.commet.soundboard.sound`, state_key = soundId.
// Per-sound events avoid whole-catalog write conflicts when two admins edit
// different sounds concurrently. Empty content ({}) = tombstone/removed.
//
// Reads from room.states cache; writes via setRoomStateWithKey; observes
// onRoomState for live sync between admins/devices. Permission gate uses
// canChangeStateEvent (power levels) — enforced here, not just in UI.
import 'dart:async';

import 'package:commet/client/components/soundboard/soundboard_component.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/client/components/soundboard/soundboard_validation.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_space.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:uuid/uuid.dart';

class MatrixSpaceSoundboardComponent extends SpaceSoundboardComponent<
    MatrixClient, MatrixSpace> {
  final StreamController<void> _onChanged =
      StreamController<void>.broadcast();
  StreamSubscription? _roomStateSub;
  List<SoundboardSound> _sounds = [];

  MatrixSpaceSoundboardComponent(
      super.client, super.space) {
    _refreshFromStates();
    _roomStateSub = matrixSpace.matrixRoom.client.onRoomState.stream
        .where((e) =>
            e.roomId == matrixSpace.matrixRoom.id &&
            e.state.type == SpaceSoundboardComponent.stateEventType)
        .listen((_) {
      _refreshFromStates();
    });
    _onChanged.add(null);
  }

  MatrixSpace get matrixSpace => space;
  MatrixClient get matrixClient => client;

  void _refreshFromStates() {
    final map = matrixSpace.matrixRoom.states[
        SpaceSoundboardComponent.stateEventType];
    final next = <SoundboardSound>[];
    if (map != null) {
      for (final entry in (map as Map).entries) {
        final stateKey = entry.key as String;
        final ev = entry.value as matrix.StrippedStateEvent;
        final content = Map<String, dynamic>.from(ev.content);
        if (content.isEmpty) continue; // tombstone
        try {
          // state_key is authoritative id; ignore mismatched body.
          content['sound_id'] = stateKey;
          next.add(SoundboardSound.fromJson(content));
        } catch (_) {
          continue; // skip malformed, never crash sync
        }
      }
    }
    next.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _sounds = next;
    if (!_onChanged.isClosed) _onChanged.add(null);
    matrixSpace.notifyUpdate();
  }

  @override
  List<SoundboardSound> get sounds => List.unmodifiable(_sounds);

  @override
  SoundboardSound? getById(String soundId) {
    for (final s in _sounds) {
      if (s.soundId == soundId) return s;
    }
    return null;
  }

  @override
  Stream<void> get onChanged => _onChanged.stream;

  @override
  bool get canManage =>
      matrixSpace.matrixRoom.canChangeStateEvent(
          SpaceSoundboardComponent.stateEventType);

  @override
  Future<SoundboardSound> addSound({
    required String name,
    required String emoji,
    required String mediaUri,
    required String mimeType,
    required int durationMs,
    required double normalizedGain,
    String? sourceUrl,
  }) async {
    if (!canManage) throw StateError('Missing permission to manage soundboard');
    final cleanName = SoundboardValidator.sanitizeName(name);
    final cleanEmoji = SoundboardValidator.sanitizeEmoji(emoji);
    if (!mediaUri.startsWith('mxc://')) {
      throw ArgumentError('mediaUri must be mxc://');
    }
    final sound = SoundboardSound(
      soundId: const Uuid().v4(),
      name: cleanName,
      emoji: cleanEmoji,
      sourceUrl: sourceUrl,
      mediaUri: mediaUri,
      mimeType: mimeType,
      durationMs: durationMs,
      normalizedGain: normalizedGain,
    );
    await matrixClient.getMatrixClient().setRoomStateWithKey(
          matrixSpace.matrixRoom.id,
          SpaceSoundboardComponent.stateEventType,
          sound.soundId,
          sound.toJson(),
        );
    _refreshFromStates();
    return sound;
  }

  @override
  Future<SoundboardSound> updateSound(
    String soundId, {
    String? name,
    String? emoji,
  }) async {
    if (!canManage) throw StateError('Missing permission to manage soundboard');
    final existing = getById(soundId);
    if (existing == null) throw StateError('Sound not found');
    final updated = existing.copyWith(
      name: name != null ? SoundboardValidator.sanitizeName(name) : null,
      emoji: emoji != null ? SoundboardValidator.sanitizeEmoji(emoji) : null,
    );
    await matrixClient.getMatrixClient().setRoomStateWithKey(
          matrixSpace.matrixRoom.id,
          SpaceSoundboardComponent.stateEventType,
          soundId,
          updated.toJson(),
        );
    _refreshFromStates();
    return updated;
  }

  @override
  Future<void> removeSound(String soundId) async {
    if (!canManage) throw StateError('Missing permission to manage soundboard');
    await matrixClient.getMatrixClient().setRoomStateWithKey(
          matrixSpace.matrixRoom.id,
          SpaceSoundboardComponent.stateEventType,
          soundId,
          {},
        );
    _refreshFromStates();
  }

  Future<void> dispose() async {
    await _roomStateSub?.cancel();
    await _onChanged.close();
  }
}
