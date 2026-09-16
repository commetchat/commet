// Entrance sound: a soundboard sound played once when the user joins a
// voice channel (Discord's "Entrance sounds").
import 'dart:async';

import 'package:commet/client/components/soundboard/soundboard_catalog.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';

/// The user's saved choice. [soundId] null = "None"; [spaceId] null = every
/// Space, otherwise only rooms of that Space.
class EntranceSoundChoice {
  final SoundId? soundId;
  final String? spaceId;

  const EntranceSoundChoice({this.soundId, this.spaceId});
}

/// Which sound to trigger on join, or null to play nothing. [roomSpaceIds]
/// are the Spaces the voice room belongs to (it can be in several); a choice
/// scoped to one Space plays when the room is in it.
SoundId? pickEntranceSound({
  required EntranceSoundChoice choice,
  required Iterable<String> roomSpaceIds,
  required SoundboardCatalog catalog,
  required bool deafened,
}) {
  final soundId = choice.soundId;
  if (soundId == null || deafened) return null;
  if (choice.spaceId != null && !roomSpaceIds.contains(choice.spaceId)) {
    return null;
  }
  // Sound ids are per-Space; one from another Space's catalog can't play here.
  if (catalog.getById(soundId) == null) return null;
  return soundId;
}

/// Makes the entrance sound fire at most once per call session, and carries
/// "join without entrance sound" requests to the voice view. The call view
/// (and its soundboard controller) is rebuilt whenever the user navigates back
/// to the room, so the controller alone can't tell a join from a revisit.
class EntranceSoundGate {
  static final EntranceSoundGate instance = EntranceSoundGate();

  /// How long a "join without entrance sound" request waits for its room's
  /// view to open. Older requests are dropped so a later visit doesn't join.
  static const Duration silentJoinRequestTtl = Duration(seconds: 10);

  final DateTime Function() _now;
  final Expando<bool> _claimed = Expando('entranceSoundClaimed');
  final Set<String> _skipRooms = {};
  final Map<String, DateTime> _silentJoinRequests = {};
  final StreamController<String> _onSilentJoinRequested =
      StreamController.broadcast();

  EntranceSoundGate({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Room ids with a new silent join request, for views that are already open.
  Stream<String> get onSilentJoinRequested => _onSilentJoinRequested.stream;

  /// Asks the voice view of [roomId] to join without the entrance sound.
  void requestSilentJoin(String roomId) {
    _silentJoinRequests[roomId] = _now();
    _onSilentJoinRequested.add(roomId);
  }

  /// True once per fresh [requestSilentJoin] for [roomId].
  bool takeSilentJoinRequest(String roomId) {
    final requestedAt = _silentJoinRequests.remove(roomId);
    return requestedAt != null &&
        _now().difference(requestedAt) <= silentJoinRequestTtl;
  }

  /// The next join of [roomId] plays no entrance sound.
  void skipNextJoin(String roomId) => _skipRooms.add(roomId);

  /// Undoes [skipNextJoin], e.g. when that join failed.
  void cancelSkip(String roomId) => _skipRooms.remove(roomId);

  /// True the first time it is called for [session], unless the join was
  /// marked with [skipNextJoin] (which this consumes).
  bool claim(Object session, {required String roomId}) {
    if (_claimed[session] == true) return false;
    _claimed[session] = true;
    return !_skipRooms.remove(roomId);
  }
}
