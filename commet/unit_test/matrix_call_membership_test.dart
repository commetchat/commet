import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_call_membership.dart';
import 'package:test/test.dart';

void main() {
  final joined = DateTime.utc(2026, 9, 16, 20);

  group('liveMediaOf', () {
    test('reads what a member reports publishing', () {
      expect(
          MatrixCallMembership.liveMediaOf({
            'chat.commet.streams': ['camera', 'screen'],
          }),
          {LiveMedia.screen, LiveMedia.camera});
    });

    test('ignores unknown values and anything that is not a list', () {
      expect(
          MatrixCallMembership.liveMediaOf({
            'chat.commet.streams': ['screen', 'hologram', 3],
          }),
          {LiveMedia.screen});
      expect(
          MatrixCallMembership.liveMediaOf({'chat.commet.streams': 'screen'}),
          isEmpty);
      expect(
          MatrixCallMembership.liveMediaOf({'application': 'm.call'}), isEmpty);
    });
  });

  group('voiceStateOf', () {
    test('reads how a member reports having silenced themselves', () {
      expect(
          MatrixCallMembership.voiceStateOf({
            'chat.commet.voice_state': ['muted'],
          }),
          {VoiceState.muted});
    });

    test('deafened implies muted', () {
      expect(
          MatrixCallMembership.voiceStateOf({
            'chat.commet.voice_state': ['deafened'],
          }),
          {VoiceState.muted, VoiceState.deafened});
    });

    test('ignores unknown values and anything that is not a list', () {
      expect(
          MatrixCallMembership.voiceStateOf({
            'chat.commet.voice_state': ['muted', 'asleep', 7],
          }),
          {VoiceState.muted});
      expect(
          MatrixCallMembership.voiceStateOf(
              {'chat.commet.voice_state': 'muted'}),
          isEmpty);
    });

    test('a client that says nothing reports nothing', () {
      expect(MatrixCallMembership.voiceStateOf({'application': 'm.call'}),
          isEmpty);
    });
  });

  group('isExpired', () {
    test('a membership lasts `expires` from when it was sent', () {
      const content = {'expires': 1000};

      expect(
          MatrixCallMembership.isExpired(
              content, joined, joined.add(const Duration(milliseconds: 999))),
          isFalse);
      expect(
          MatrixCallMembership.isExpired(
              content, joined, joined.add(const Duration(milliseconds: 1001))),
          isTrue);
    });

    test('a rewritten membership counts from its join time', () {
      // Rewritten 4 s after joining: MatrixRTC clients count `expires` from
      // created_ts, not from the rewrite.
      final content = {
        'expires': 5000,
        'created_ts': joined.millisecondsSinceEpoch,
      };
      final rewrittenAt = joined.add(const Duration(seconds: 4));

      expect(
          MatrixCallMembership.isExpired(content, rewrittenAt,
              joined.add(const Duration(milliseconds: 5001))),
          isTrue);
    });

    test('stripped state, which has no timestamp, does not expire', () {
      expect(
          MatrixCallMembership.isExpired(
              const {'expires': 1}, null, joined.add(const Duration(days: 1))),
          isFalse);
    });
  });

  group('withPublishedState', () {
    final joinContent = {
      'application': 'm.call',
      'call_id': '',
      'device_id': 'DEVICEA',
      'expires': 14400000,
      'focus_active': {
        'focus_selection': 'oldest_membership',
        'type': 'livekit'
      },
      'foci_preferred': [
        {
          'type': 'livekit',
          'livekit_alias': '!voice:x',
          'livekit_service_url': 'https://lk.x'
        }
      ],
      'scope': 'm.room',
      'chat.commet.streams': <String>[],
    };

    test('lists the streams and keeps the rest of the membership', () {
      final content = MatrixCallMembership.withPublishedState(joinContent,
          media: {LiveMedia.camera, LiveMedia.screen},
          voiceState: {VoiceState.deafened, VoiceState.muted},
          joinedAt: joined,
          now: joined);

      expect(content['chat.commet.streams'], ['screen', 'camera']);
      expect(content['chat.commet.voice_state'], ['muted', 'deafened']);
      for (final key in ['application', 'call_id', 'device_id', 'scope']) {
        expect(content[key], joinContent[key]);
      }
      expect(content['focus_active'], joinContent['focus_active']);
      expect(content['foci_preferred'], joinContent['foci_preferred']);
    });

    test('keeps the join time and pushes the expiry 4 h past now', () {
      final content = MatrixCallMembership.withPublishedState(joinContent,
          media: const {},
          voiceState: const {},
          joinedAt: joined,
          now: joined.add(const Duration(hours: 1)));

      expect(content['created_ts'], joined.millisecondsSinceEpoch);
      expect(content['expires'], const Duration(hours: 5).inMilliseconds);
      expect(content['chat.commet.streams'], isEmpty);
      expect(content['chat.commet.voice_state'], isEmpty);
      expect(
          MatrixCallMembership.isExpired(
              content,
              joined.add(const Duration(hours: 1)),
              joined.add(const Duration(hours: 4, minutes: 59))),
          isFalse);
    });
  });
}
