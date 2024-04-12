import 'package:flutter/widgets.dart';

enum VoipStreamType { audio, video, screenshare }

abstract class VoipStream {
  VoipStreamType get type;

  Widget? get videoRender;

  String get streamUserId;

  String get label;

  double get audiolevel;
}
