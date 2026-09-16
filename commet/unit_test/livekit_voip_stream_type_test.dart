import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_stream.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:test/test.dart';

void main() {
  group("MatrixLivekitVoipStream.typeOf", () {
    test("microphone audio is an audio stream", () {
      expect(
          MatrixLivekitVoipStream.typeOf(
              lk.TrackType.AUDIO, lk.TrackSource.microphone),
          VoipStreamType.audio);
    });

    test("screen share audio is a screenshareAudio stream, not audio", () {
      expect(
          MatrixLivekitVoipStream.typeOf(
              lk.TrackType.AUDIO, lk.TrackSource.screenShareAudio),
          VoipStreamType.screenshareAudio);
    });

    test("screen share video is a screenshare stream", () {
      expect(
          MatrixLivekitVoipStream.typeOf(
              lk.TrackType.VIDEO, lk.TrackSource.screenShareVideo),
          VoipStreamType.screenshare);
    });

    test("camera video is a video stream", () {
      expect(
          MatrixLivekitVoipStream.typeOf(
              lk.TrackType.VIDEO, lk.TrackSource.camera),
          VoipStreamType.video);
    });
  });
}
