import 'package:flutter/widgets.dart';

enum VoipStreamType { audio, video, screenshare }

enum VoipStreamDirection { incoming, outgoing }

abstract class VoipStream {
  VoipStreamType get type;

  VoipStreamDirection get direction;

  Widget? buildVideoRenderer(BoxFit fit, Key key);

  String get streamUserId;

  String get label;

  String get streamId;

  double get audiolevel;

  double? get aspectRatio;
}
