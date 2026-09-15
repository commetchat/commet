// LiveKit data-channel transport for soundboard triggers.
//
// Uses lk.LocalParticipant.publishData (reliable) on topic
// `chat.commet.soundboard.v1`, and listens for DataReceivedEvent with the
// same topic. Payload is SoundboardEvent JSON (utf8). Identity comes from
// the LiveKit participant (mapped back to Matrix userId by the caller);
// event.senderId is only a hint.
//
// Why reliable=true: triggers are tiny (<300 bytes) and must not be lost;
// LiveKit reliable data still arrives in tens of ms on a healthy SFU call,
// well within the "few hundred ms" UX budget. Lossy would save ~ms but drop
// playful triggers — wrong tradeoff.
import 'dart:async';

import 'package:commet/client/components/soundboard/soundboard_event.dart';
import 'package:commet/client/components/soundboard/soundboard_transport.dart';
import 'package:commet/debug/log.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class LivekitSoundboardTransport implements SoundboardTransport {
  final lk.Room room;

  /// Maps LiveKit participant identity ("@user:server:device...") back to a
  /// Matrix userId ("@user:server"). Matches MatrixLivekitVoipSession's
  /// `split(":").take(2)` convention.
  final String Function(String identity)? identityToUserId;

  final StreamController<TransportIncoming> _controller =
      StreamController<TransportIncoming>.broadcast();

  late final lk.EventsListener<lk.RoomEvent> _roomListener;

  LivekitSoundboardTransport(this.room, {this.identityToUserId}) {
    final listener = room.createListener();
    _roomListener = listener;
    listener.on<lk.DataReceivedEvent>((e) {
      if (e.topic != SoundboardEvent.livekitTopic) return;
      final event = SoundboardEvent.tryParseBytes(e.data);
      if (event == null) return; // ignore foreign topics/malformed
      final rawIdentity = e.participant?.identity ?? '';
      final userId = identityToUserId?.call(rawIdentity) ??
          _defaultIdentityToUserId(rawIdentity);
      _controller.add(TransportIncoming(event,
          authenticatedSenderId: userId.isEmpty ? null : userId));
    });
  }

  static String _defaultIdentityToUserId(String identity) {
    if (identity.isEmpty) return '';
    final parts = identity.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return identity;
  }

  @override
  Future<void> send(SoundboardEvent event) async {
    try {
      await room.localParticipant?.publishData(
        event.encode(),
        reliable: true,
        topic: SoundboardEvent.livekitTopic,
      );
    } catch (e, s) {
      Log.onError(e, s, content: 'Soundboard publishData failed');
      rethrow;
    }
  }

  @override
  Stream<TransportIncoming> get incoming => _controller.stream;

  @override
  Future<void> dispose() async {
    await _roomListener.dispose();
    await _controller.close();
  }
}
