import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_session.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:test/test.dart';

/// The frame rate and bitrate the share publishes with in these tests.
const framerate = 60;
const bitrate = 8000000;

lk.VideoPublishOptions build({String codec = 'h265', bool e2ee = false}) =>
    buildScreenSharePublishOptions(
      codec: codec,
      framerate: framerate,
      bitrate: bitrate,
      simulcast: false,
      e2ee: e2ee,
    );

void main() {
  test('the primary stream carries the requested encoding', () {
    final options = build();

    expect(options.videoCodec, 'h265');
    expect(options.screenShareEncoding!.maxFramerate, framerate);
    expect(options.screenShareEncoding!.maxBitrate, bitrate);
    expect(options.videoEncoding!.maxFramerate, framerate);
    expect(options.videoEncoding!.maxBitrate, bitrate);
  });

  test('the backup codec carries the requested frame rate and bitrate', () {
    final options = build();

    // With H.265 the SFU regresses viewers that cannot decode it to the
    // backup codec. Left to the SDK, its encoding came from a screen-share
    // preset capped at 15 FPS: the low frame rate seen with H.265 (issue #79).
    expect(options.backupVideoCodec.enabled, isTrue);
    expect(options.backupVideoCodec.codec, 'vp8');
    expect(options.backupVideoCodec.encoding!.maxFramerate, framerate);
    expect(options.backupVideoCodec.encoding!.maxBitrate, bitrate);
  });

  test('the degradation preference keeps the frame rate under load', () {
    final options = build();

    expect(options.degradationPreference,
        lk.DegradationPreference.maintainFramerate,
        reason: 'the backup sender must not silently degrade to a lower '
            'frame rate than the primary');
  });

  test('E2EE rooms publish no backup codec', () {
    final options = build(e2ee: true);

    expect(options.backupVideoCodec.enabled, isFalse,
        reason: 'multi-codec simulcast is not supported with frame '
            'encryption, and the SDK disables the backup codec for E2EE rooms');
  });

  test('simulcast follows the preference for both codecs', () {
    final options = buildScreenSharePublishOptions(
      codec: 'vp8',
      framerate: framerate,
      bitrate: bitrate,
      simulcast: true,
      e2ee: false,
    );

    expect(options.simulcast, isTrue);
    expect(options.backupVideoCodec.simulcast, isTrue);
  });
}
