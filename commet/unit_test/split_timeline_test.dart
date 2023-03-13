import 'package:commet/client/client.dart';
import 'package:commet/client/simulated/simulated_client.dart';
import 'package:commet/client/simulated/simulated_room.dart';
import 'package:commet/client/split_timeline.dart';
import 'package:test/test.dart';

void main() async {
  Future<Client> generateClient() async {
    Client client = SimulatedClient();
    await client.login(LoginType.loginPassword, "Simulated", "");
    var room = client.rooms[0];

    for (int i = 0; i < 100; i++) {
      (room as SimulatedRoom).addRandomEvent(0);
    }
    return client;
  }

  test("SplitTimeline: whichList", () async {
    var client = await generateClient();
    var room = client.rooms[0];

    int chunkSize = 20;
    SplitTimeline split = SplitTimeline(room.timeline!, chunkSize: chunkSize);

    expect(split.whichList(0), SplitTimelinePart.recent);
    expect(split.whichList(chunkSize - 1), SplitTimelinePart.recent);
    expect(split.whichList(chunkSize), SplitTimelinePart.historical);

    int notYetLoadedIndex = (chunkSize * 2) + 5;

    expect(split.whichList(notYetLoadedIndex), SplitTimelinePart.none);
    expect(split.isMoreHistoryAvailable(), true);

    split.loadMoreHistory();

    expect(split.whichList(notYetLoadedIndex), SplitTimelinePart.historical);
    expect(split.whichList(room.timeline!.events.length + 20), SplitTimelinePart.none);
  });

  test("SplitTimeline: Indexing", () async {
    var client = await generateClient();
    var room = client.rooms[0];

    int chunkSize = 20;
    SplitTimeline split = SplitTimeline(room.timeline!, chunkSize: chunkSize);

    void ensureIndices(int index) {
      switch (split.whichList(index)) {
        case SplitTimelinePart.historical:
          int result = split.getHistoryIndex(index);
          expect(room.timeline!.events[index], split.historical[result]);

          int reverse = split.getTimelineIndex(result, SplitTimelinePart.historical);
          expect(index, reverse);

          break;
        case SplitTimelinePart.recent:
          int result = split.getRecentIndex(index);
          expect(room.timeline!.events[index], split.recent[result]);

          int reverse = split.getTimelineIndex(result, SplitTimelinePart.recent);
          expect(index, reverse);
          break;
        case SplitTimelinePart.none:
          break;
      }
    }

    for (int i = 0; i < split.numEventsLoaded(); i++) {
      ensureIndices(i);
    }

    split.loadMoreHistory();

    for (int i = 0; i < split.numEventsLoaded(); i++) {
      ensureIndices(i);
    }
  });

  test("SplitTimeline: Insertion Parts", () async {
    var client = await generateClient();
    var room = client.rooms[0];

    int chunkSize = 20;
    SplitTimeline split = SplitTimeline(room.timeline!, chunkSize: chunkSize);
    expect(split.whichListToInsert(0), SplitTimelinePart.recent);
    expect(split.whichListToInsert(chunkSize), SplitTimelinePart.historical);
  });

  test("SplitTimeline: Insertion in to recent", () async {
    var client = await generateClient();
    var room = client.rooms[0];

    int chunkSize = 20;
    SplitTimeline split = SplitTimeline(room.timeline!, chunkSize: chunkSize);

    int testIndex = 5;

    var event = (room as SimulatedRoom).generateRandomEvent();

    room.timeline!.onEventAdded.stream.listen(expectAsync1((int index) {
      expect(index, testIndex);
      expect(event, split.recent[split.getRecentIndex(index)]);
    }));

    room.timeline!.insertEvent(testIndex, event);
  });

  test("SplitTimeline: Insertion in to history", () async {
    var client = await generateClient();
    var room = client.rooms[0];

    int chunkSize = 20;
    SplitTimeline split = SplitTimeline(room.timeline!, chunkSize: chunkSize);

    int testIndex = chunkSize + 5;

    var event = (room as SimulatedRoom).generateRandomEvent();

    room.timeline!.onEventAdded.stream.listen(expectAsync1((int index) {
      expect(index, testIndex);
      expect(event, split.historical[split.getHistoryIndex(index)]);
    }));

    room.timeline!.insertEvent(testIndex, event);
  });

  test("SplitTimeline: Is History Available", () async {
    var client = await generateClient();
    var room = client.rooms[0];

    int chunkSize = 20;
    SplitTimeline split = SplitTimeline(room.timeline!, chunkSize: chunkSize);

    expect(split.isMoreHistoryAvailable(), true);

    split.loadMoreHistory();
    split.loadMoreHistory();
    split.loadMoreHistory();
    split.loadMoreHistory();
    split.loadMoreHistory();
    split.loadMoreHistory();

    expect(split.isMoreHistoryAvailable(), false);
  });
}
