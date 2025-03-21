import 'package:commet/client/components/voip_room/voip_room_component.dart';
import 'package:commet/client/matrix/components/matrix_sync_listener.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/matrix_api_lite/model/sync_update.dart';

class MatrixVoipRoomComponent
    implements
        VoipRoomComponent<MatrixClient, MatrixRoom>,
        MatrixRoomSyncListener {
  @override
  MatrixClient client;

  @override
  MatrixRoom room;

  MatrixVoipRoomComponent(this.client, this.room);

  @override
  bool get isVoipRoom =>
      room.matrixRoom.getState(EventTypes.RoomCreate)?.content['type'] ==
      "org.matrix.msc3417.call";

  @override
  onSync(JoinedRoomUpdate update) {}
}
