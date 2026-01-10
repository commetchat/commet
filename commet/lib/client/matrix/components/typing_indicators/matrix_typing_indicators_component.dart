import 'dart:async';

import 'package:commet/client/components/typing_indicators/typing_indicator_component.dart';
import 'package:commet/client/matrix/components/matrix_sync_listener.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_member.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/member.dart';
import 'package:matrix/matrix_api_lite/model/sync_update.dart';

class MatrixTypingIndicatorsComponent
    implements
        TypingIndicatorComponent<MatrixClient, MatrixRoom>,
        MatrixRoomSyncListener {
  @override
  MatrixClient client;
  @override
  MatrixRoom room;

  MatrixTypingIndicatorsComponent(this.client, this.room);

  final StreamController<void> _controller = StreamController.broadcast();

  @override
  onSync(JoinedRoomUpdate update) {
    final ephemeral = update.ephemeral;

    if (ephemeral == null) {
      return;
    }

    if (ephemeral.any((e) => e.type == "m.typing")) {
      _controller.add(null);
    }
  }

  @override
  Stream<void> get onTypingUsersUpdated => _controller.stream;

  @override
  List<Member> get typingUsers => room.matrixRoom.typingUsers
      .where((element) => client.self?.identifier != element.id)
      .map((e) => MatrixMember(client, e))
      .toList();

  @override
  Future<void> setTypingStatus(bool status) {
    return room.matrixRoom.setTyping(status, timeout: 2000);
  }
}
