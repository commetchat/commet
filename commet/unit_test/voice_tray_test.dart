import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/utils/voice_tray.dart';
import 'package:test/test.dart';

class _Session implements VoipSession {
  _Session(this.state,
      {this.isMicrophoneMuted = false, this.isDeafened = false});

  @override
  final VoipState state;
  @override
  final bool isMicrophoneMuted;
  @override
  final bool isDeafened;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group("Tray icon", () {
    test("the logo when not in a call", () {
      expect(VoiceTray.statusOf([]), VoiceTrayStatus.idle);
    });

    test("a ringing or ended call is not being in a call", () {
      expect(
          VoiceTray.statusOf(
              [_Session(VoipState.incoming), _Session(VoipState.ended)]),
          VoiceTrayStatus.idle);
    });

    test("a mic while heard", () {
      expect(VoiceTray.statusOf([_Session(VoipState.connected)]),
          VoiceTrayStatus.live);
    });

    test("a muted mic while muted", () {
      expect(
          VoiceTray.statusOf(
              [_Session(VoipState.connected, isMicrophoneMuted: true)]),
          VoiceTrayStatus.muted);
    });

    test("a muted mic while deafened", () {
      expect(
          VoiceTray.statusOf([_Session(VoipState.connected, isDeafened: true)]),
          VoiceTrayStatus.muted);
    });

    test("heard in any call counts as heard", () {
      expect(
          VoiceTray.statusOf([
            _Session(VoipState.connected, isMicrophoneMuted: true),
            _Session(VoipState.connecting),
          ]),
          VoiceTrayStatus.live);
    });
  });
}
