import 'package:commet/client/preview_data.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixRoomPreview extends PreviewData {
  late matrix.Client _matrixClient;

  MatrixRoomPreview(
      {required String roomId, required matrix.Client matrixClient})
      : super(roomId: roomId) {
    _matrixClient = matrixClient;
  }

  Future<void> init() async {
    var state = await _matrixClient.getRoomState(roomId);

    var nameState = state.where((element) => element.type == "m.room.name");
    if (nameState.isNotEmpty) displayName = nameState.first.content['name'];

    var avatarState = state.where((element) => element.type == "m.room.avatar");
    if (avatarState.isNotEmpty) {
      var mxc = Uri.parse(avatarState.first.content['url']);
      var thumbnail = mxc.getDownloadLink(_matrixClient);
      avatar = NetworkImage(thumbnail.toString());
    }

    var topicState = state.where((element) => element.type == "m.room.topic");
    if (topicState.isNotEmpty) topic = topicState.first.content['topic'];
    exists = true;
  }
}
