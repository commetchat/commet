import 'package:flutter/widgets.dart';

enum VoipStreamType {
  audio,
  video,
  screenshare,

  /// System audio captured alongside a screen share. Belongs to the same
  /// member as their [screenshare] stream and is never drawn as its own
  /// tile; the call grid folds it into the screen share tile.
  screenshareAudio,
}

enum VoipStreamDirection { incoming, outgoing }

abstract class VoipStream {
  VoipStreamType get type;

  VoipStreamDirection get direction;

  Widget? buildVideoRenderer(BoxFit fit, Key key);

  Stream<void> get onStreamChanged;

  String get streamUserId;

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
}
