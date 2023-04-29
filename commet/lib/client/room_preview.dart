import 'package:flutter/widgets.dart';

class PreviewData {
  String roomId;
  ImageProvider? avatar;
  String? displayName;
  String? topic;

  PreviewData(
      {required this.roomId, this.avatar, this.displayName, this.topic});
}
