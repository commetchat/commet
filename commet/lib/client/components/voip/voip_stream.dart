import 'package:flutter/widgets.dart';

enum VoipStreamType { audio, video, screenshare }

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

  double? get aspectRatio;

  double get volume;

  Future<void> setVolume(double volume);
}
