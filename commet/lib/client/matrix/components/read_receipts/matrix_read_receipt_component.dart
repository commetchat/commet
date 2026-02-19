import 'dart:async';

import 'package:commet/client/components/read_receipts/read_receipt_component.dart';
import 'package:commet/client/matrix/components/matrix_sync_listener.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:matrix/matrix_api_lite/model/sync_update.dart';

class MatrixReadReceiptComponent
    implements
        ReadReceiptComponent<MatrixClient, MatrixRoom>,
        MatrixRoomSyncListener {
  @override
  MatrixClient client;
  @override
  MatrixRoom room;

  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  @override
  Stream<String> get onReadReceiptsUpdated => _controller.stream;

  MatrixReadReceiptComponent(this.client, this.room) {
    room.onTimelineLoaded.stream.listen(onTimelineLoaded);
  }

  Map<String, String> userToPreviousReceipt = {};

  @override
  onSync(JoinedRoomUpdate update) {
    final ephemeral = update.ephemeral;

    if (ephemeral == null) {
      return;
    }

    for (var event in ephemeral) {
      if (event.type == "m.receipt") {
        for (var key in event.content.keys) {
          var e = (event.content[key]! as Map<String, dynamic>)["m.read"];
          if (e == null) continue;

          if (e is Map<String, dynamic>) {
            for (var k in e.keys) {
              var lastEvent = userToPreviousReceipt[k];
              if (lastEvent != null) {
                _controller.add(lastEvent);
              }

              userToPreviousReceipt[k] = key;
            }
          }

          _controller.add(key);
        }
      }
    }
  }

  void handleEvent(String eventId, String userId) {
    var lastEvent = userToPreviousReceipt[userId];
    if (lastEvent != null) {
      _controller.add(lastEvent);
    }

    userToPreviousReceipt[userId] = eventId;
    _controller.add(eventId);
  }

  void onTimelineLoaded(void event) {}

  @override
  List<String>? getReceipts(TimelineEvent event) {
    if (room.timeline == null) {
      return null;
    }

    var timeline = (room.timeline as MatrixTimeline);
    if (timeline.matrixTimeline == null) {
      return null;
    }

    if (event is! MatrixTimelineEvent) return [];

    var receipts = event.event.receipts;

    for (var receipt in receipts) {
      userToPreviousReceipt[receipt.user.id] = event.eventId;
    }

    return receipts
        .where((i) => i.user.id != client.self!.identifier)
        .map((i) => i.user.id)
        .toList();
  }
}
