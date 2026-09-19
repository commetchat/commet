import 'package:flutter/widgets.dart';

enum VoipStreamType {
  audio,
  video,
  screenshare,

  /// System audio captured alongside a screen share. Belongs to the same
  /// member as their [screenshare] stream and is never drawn as its own
  /// tile; the call grid folds it into the screen share tile.
  screenshareAudio,

  /// The DJ booth's music. Nobody's voice: no tile, no speaking indicator,
  /// and one volume for all of it, set in the booth.
  music,
}

enum VoipStreamDirection { incoming, outgoing }

abstract class VoipStream {
  VoipStreamType get type;

  VoipStreamDirection get direction;

  Widget? buildVideoRenderer(BoxFit fit, Key key);

  Stream<void> get onStreamChanged;

  String get streamUserId;

  /// Who published this stream, telling two devices of the same account
  /// apart. [streamUserId] is what the volume preference is keyed by, so it
  /// stays per user.
  String get streamOwnerId;

  String get label;

  String get streamId;

  String get stats;

  double get audiolevel;

  bool get isMuted;

  /// Whether the owner of this stream has deafened themselves (stopped
  /// listening). Implies muted; shown with a distinct badge.
  bool get isDeafened;

  double? get aspectRatio;

  double get volume;

  Future<void> setVolume(double volume);

  /// Whether this stream only plays once the user opts in to watching it.
  /// True for someone else's screen share in a voice room: like Discord, no
  /// video is downloaded and no screen audio plays until they click "Watch
  /// stream".
  bool get requiresWatching;

  /// Whether the user is watching this stream. Always true for streams that
  /// don't [requiresWatching].
  bool get isWatching;

  /// Starts watching: subscribes to the screen share video and its audio.
  Future<void> watch();

  /// Stops watching: unsubscribes from the screen share video and its audio.
  /// The sharer's mic is not affected.
  Future<void> stopWatching();
}
