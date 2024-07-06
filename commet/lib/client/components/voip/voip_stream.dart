import 'package:flutter/widgets.dart';

enum VoipStreamType { audio, video, screenshare }

abstract class VoipStream {
  VoipStreamType get type;

  Widget? buildVideoRenderer(BoxFit fit, Key key);

  String get streamUserId;

  String get label;

  String get streamId;

  double get audiolevel;

  double? get aspectRatio;
}
