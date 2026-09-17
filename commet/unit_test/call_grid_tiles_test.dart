import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/ui/organisms/call_view/call_grid_tiles.dart';
import 'package:test/test.dart';

class FakeVoipStream implements VoipStream {
  @override
  final String streamId;
  @override
  final String streamUserId;
  @override
  final VoipStreamType type;
  @override
  final VoipStreamDirection direction;

  FakeVoipStream(this.streamId,
      {required this.streamUserId,
      required this.type,
      this.direction = VoipStreamDirection.incoming});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const alice = "@alice:example.org";
  const bob = "@bob:example.org";

  group("callGridTiles", () {
    test(
        "our own screen share does not pick up the audio of our other device's share",
        () {
      final ownScreen = FakeVoipStream("own-screen",
          streamUserId: alice,
          type: VoipStreamType.screenshare,
          direction: VoipStreamDirection.outgoing);
      final otherDeviceScreen = FakeVoipStream("other-screen",
          streamUserId: alice, type: VoipStreamType.screenshare);
      final otherDeviceAudio = FakeVoipStream("other-audio",
          streamUserId: alice, type: VoipStreamType.screenshareAudio);

      final tiles =
          callGridTiles([ownScreen, otherDeviceScreen, otherDeviceAudio]);

      expect(tiles.firstWhere((t) => t.stream == ownScreen).audioStream, null);
      expect(tiles.firstWhere((t) => t.stream == otherDeviceScreen).audioStream,
          otherDeviceAudio);
    });

    test(
        "a member sharing their screen with audio gets one avatar tile and one screen share tile",
        () {
      final mic = FakeVoipStream("mic",
          streamUserId: alice, type: VoipStreamType.audio);
      final screen = FakeVoipStream("screen",
          streamUserId: alice, type: VoipStreamType.screenshare);
      final screenAudio = FakeVoipStream("screen-audio",
          streamUserId: alice, type: VoipStreamType.screenshareAudio);

      final tiles = callGridTiles([mic, screen, screenAudio]);

      expect(tiles.map((t) => t.stream), equals([mic, screen]));
      expect(tiles[0].audioStream, isNull);
      expect(tiles[1].audioStream, same(screenAudio));
    });

    test("screen share without audio has no audio stream on its tile", () {
      final mic = FakeVoipStream("mic",
          streamUserId: alice, type: VoipStreamType.audio);
      final screen = FakeVoipStream("screen",
          streamUserId: alice, type: VoipStreamType.screenshare);

      final tiles = callGridTiles([mic, screen]);

      expect(tiles.map((t) => t.stream), equals([mic, screen]));
      expect(tiles[1].audioStream, isNull);
    });

    test("screen share audio is matched to its own member, not to others", () {
      final aliceMic = FakeVoipStream("alice-mic",
          streamUserId: alice, type: VoipStreamType.audio);
      final aliceScreen = FakeVoipStream("alice-screen",
          streamUserId: alice, type: VoipStreamType.screenshare);
      final bobMic = FakeVoipStream("bob-mic",
          streamUserId: bob, type: VoipStreamType.audio);
      final bobScreen = FakeVoipStream("bob-screen",
          streamUserId: bob, type: VoipStreamType.screenshare);
      final bobScreenAudio = FakeVoipStream("bob-screen-audio",
          streamUserId: bob, type: VoipStreamType.screenshareAudio);

      final tiles = callGridTiles(
          [aliceMic, aliceScreen, bobMic, bobScreenAudio, bobScreen]);

      expect(tiles.map((t) => t.stream),
          equals([aliceMic, aliceScreen, bobMic, bobScreen]));
      expect(tiles[1].audioStream, isNull);
      expect(tiles[3].audioStream, same(bobScreenAudio));
    });

    test("camera video tiles are kept as they are", () {
      final mic = FakeVoipStream("mic",
          streamUserId: alice, type: VoipStreamType.audio);
      final camera = FakeVoipStream("camera",
          streamUserId: alice, type: VoipStreamType.video);

      final tiles = callGridTiles([mic, camera]);

      expect(tiles.map((t) => t.stream), equals([mic, camera]));
      expect(tiles.every((t) => t.audioStream == null), isTrue);
    });
  });
}
