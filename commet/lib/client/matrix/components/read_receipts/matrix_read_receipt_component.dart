import 'dart:async';

import 'package:commet/client/components/read_receipts/read_receipt_component.dart';
import 'package:commet/client/matrix/components/matrix_sync_listener.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/debug/log.dart';
import 'package:matrix/matrix_api_lite/model/sync_update.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixReadReceiptComponent
    implements
        ReadReceiptComponent<MatrixClient, MatrixRoom>,
        MatrixRoomSyncListener {
  @override
  MatrixClient client;
  @override
  MatrixRoom room;

  final StreamController _controller = StreamController.broadcast();

  @override
  Stream<void> get onReadReceiptsUpdated => _controller.stream;

  @override
  List<String> get receipts => getReceipts() ?? [];

  MatrixReadReceiptComponent(this.client, this.room) {
    room.onTimelineLoaded.stream.listen(onTimelineLoaded);
  }

  @override
  onSync(JoinedRoomUpdate update) {
    Log.d("Read Receipt Component got sync for room: ${room.identifier}!");
    final ephemeral = update.ephemeral;

    if (update.timeline?.events?.isNotEmpty == true) {
      _controller.add(null);
    }

    if (ephemeral == null) {
      return;
    }

    if (ephemeral.any((e) => e.type == "m.receipt")) {
      Log.i("Received read receipt update");
      _controller.add(null);
    }
  }

  void onTimelineLoaded(void event) {
    _controller.add(null);
  }

  List<String>? getReceipts() {
    if (room.timeline == null) {
      return null;
    }

    var timeline = (room.timeline as MatrixTimeline);
    if (timeline.matrixTimeline == null) {
      return null;
    }

    var matrixTimeline = timeline.matrixTimeline!;

    var state = matrixTimeline.room.receiptState;

    const displayableTypes = [
      matrix.EventTypes.Message,
      matrix.EventTypes.Sticker,
    ];

    Set<String> ids = {};
    matrix.Event? latestDisplayableEvent;
    for (int i = 0; i < matrixTimeline.events.length; i++) {
      var event = matrixTimeline.events[i];
      ids.add(event.eventId);

      if (displayableTypes.contains(event.type)) {
        latestDisplayableEvent = event;
        break;
      }
    }

    var receipts = state.global.otherUsers.entries
        .where((element) => ids.contains(element.value.eventId))
        .map((entry) => entry.key)
        .toList(growable: true);

    if (latestDisplayableEvent != null &&
        latestDisplayableEvent.senderId != client.self!.identifier &&
        !receipts.contains(latestDisplayableEvent.senderId))
      receipts.add(latestDisplayableEvent.senderId);

    return receipts;
  }
}
