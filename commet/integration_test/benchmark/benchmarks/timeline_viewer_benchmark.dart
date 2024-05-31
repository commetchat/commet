import 'dart:math';

import 'package:commet/client/matrix/matrix_profile.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/ui/molecules/timeline_viewer.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/src/models/timeline_chunk.dart' as c;

import 'package:tiamat/config/style/theme_dark.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  var client = MatrixClient(identifier: "benchmark");
  client.self = MatrixProfile(client.getMatrixClient(),
      matrix.Profile(userId: '@benchy:matrix.org', displayName: 'benchy'));

  var room = client.createRoomWithData();
  var timeline = room.getBenchmarkTimeline();

  testWidgets('Timeline Viewer Test', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      theme: ThemeDark.theme,
      home: Scaffold(
        body: TimelineViewer(
          timeline: timeline,
        ),
      ),
    ));

    await tester.pump(const Duration(seconds: 1));

    final listFinder = find.byType(Scrollable);
    final itemFinder = find.text(finalEventMessage);

    await binding.traceAction(
      () async {
        // Scroll until the item to be found appears.
        await tester.scrollUntilVisible(
          itemFinder,
          50.0,
          maxScrolls: 1000,
          scrollable: listFinder,
        );
      },
      reportKey: 'TimelineViewer Scrolling',
    );
  });
}

const _userId = "@benchy:example.com";
const _roomId = "!benchmark:example.com";
const finalEventMessage = "End Test Here";

extension BenchmarkUtils on MatrixClient {
  MatrixRoom createRoomWithData() {
    var mxRoom = matrix.Room.fromJson({
      'id': _roomId,
      'notification_count': 0,
      'highlight_count': 0,
      'prev_batch': 'fake_batch_id',
      'summary': {
        'm.joined_member_count': 100,
        'm.invited_member_count': 0,
      },
    }, getMatrixClient());

    mxRoom.setState(matrix.Event.fromJson({
      'type': 'm.room.member',
      'state_key': _userId,
      'sender': _userId,
      'content': {'display_name': 'Benchy', 'membership': 'join'}
    }, mxRoom));

    var room = MatrixRoom(this, mxRoom, getMatrixClient());
    rooms.add(room);
    return room;
  }
}

extension BenchmarkTimeline on MatrixRoom {
  MatrixTimeline getBenchmarkTimeline() {
    var chunk = c.TimelineChunk(events: [
      for (var i = 0; i < 100; i++) createRandomEvent(i),
      createTestEndEvent(100),

      // create more events so it doent try to fetch more from server
      for (var i = 0; i < 50; i++) createRandomEvent(101 + i),
    ]);

    var mxTimeline = matrix.Timeline(chunk: chunk, room: matrixRoom);

    return MatrixTimeline(client, this, matrixRoom,
        initialTimeline: mxTimeline);
  }

  matrix.Event createTestEndEvent(int eventCount) {
    var event = matrix.Event.fromJson({
      'event_id': '\$final',
      'type': 'm.room.message',
      'content': {'body': finalEventMessage, 'msgtype': 'm.text'},
      'sender': _userId,
      'room_id': matrixRoom.id,
      'origin_server_ts': DateTime.now()
          .subtract(Duration(days: eventCount))
          .millisecondsSinceEpoch
    }, matrixRoom);

    return event;
  }

  matrix.Event createRandomEvent(int seed) {
    final r = Random(seed);

    var relatedEventId = '\$${seed + 5}';
    bool canBeRelatedEvent = seed < 90;

    // var json = {
    //   'event_id': '\$$seed',
    //   'sender': _userId,
    //   'room_id': matrixRoom.id,
    //   'origin_server_ts':
    //       DateTime.now().subtract(Duration(days: seed)).millisecondsSinceEpoch
    // };

    // if (r.nextDouble() < 0.2 && canBeRelatedEvent) {
    //   json['type'] = 'm.reaction';
    //   json['content'] = {
    //     'm.relates_to': {
    //       'event_id': relatedEventId,
    //       'rel_type': 'm.annotation',
    //       'key': r.nextBool() ? 'String Reaction' : "❤️"
    //     }
    //   };

    //   return matrix.Event.fromJson(json, matrixRoom);
    // }

    var contentLength = r.nextInt(200) + 10;

    bool isThreadReply = r.nextBool();

    var event = matrix.Event.fromJson({
      'event_id': '\$$seed',
      'type': 'm.room.message',
      'content': {
        'body': '($seed) ${RandomUtils.getRandomSentence(contentLength)}',
        'msgtype': 'm.text',
        if (canBeRelatedEvent)
          'm.relates_to': {
            if (isThreadReply) 'event_id': relatedEventId,
            if (isThreadReply) 'rel_type': 'm.thread',
            if (isThreadReply) 'is_falling_back': true,
            if (isThreadReply == false)
              'm.in_reply_to': {'event_id': relatedEventId}
          },
      },
      'sender': _userId,
      'room_id': matrixRoom.id,
      'origin_server_ts':
          DateTime.now().subtract(Duration(days: seed)).millisecondsSinceEpoch
    }, matrixRoom);

    return event;
  }
}
