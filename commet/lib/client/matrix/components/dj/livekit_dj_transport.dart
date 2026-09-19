// The DJ booth's messages over LiveKit's data channel (reliable, topic
// DjProtocol.topic), like the soundboard's triggers. The sender is the
// LiveKit participant the SFU delivered the packet from, not anything the
// packet says.
import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_protocol.dart';
import 'package:commet/debug/log.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class LivekitDjTransport implements DjTransport {
  final lk.Room room;

  final StreamController<DjIncoming> _incoming = StreamController.broadcast();
  final StreamController<String> _joined = StreamController.broadcast();
  final StreamController<String> _left = StreamController.broadcast();
  late final lk.EventsListener<lk.RoomEvent> _listener;

  LivekitDjTransport(this.room) {
    _listener = room.createListener()
      ..on<lk.DataReceivedEvent>((e) {
        if (e.topic != DjProtocol.topic) return;
        final sender = e.participant?.identity;
        if (sender == null) return;
        final message = DjProtocol.decodePacket(Uint8List.fromList(e.data));
        if (message == null) return;
        _incoming.add(DjIncoming(sender, message));
      })
      ..on<lk.ParticipantConnectedEvent>(
          (e) => _joined.add(e.participant.identity))
      ..on<lk.ParticipantDisconnectedEvent>(
          (e) => _left.add(e.participant.identity))
      ..on<lk.RoomReconnectedEvent>((_) => _reconnected.add(null));
  }

  final StreamController<void> _reconnected = StreamController.broadcast();

  @override
  Stream<void> get reconnected => _reconnected.stream;

  @override
  String get selfIdentity => room.localParticipant?.identity ?? '';

  @override
  Future<void> send(Map<String, Object?> message, {List<String>? to}) async {
    final participant = room.localParticipant;
    if (participant == null) return;
    try {
      await participant.publishData(
        DjProtocol.encodePacket(message),
        reliable: true,
        topic: DjProtocol.topic,
        destinationIdentities: to,
      );
    } catch (e, s) {
      Log.onError(e, s, content: 'DJ booth: could not send ${message['t']}');
      rethrow;
    }
  }

  @override
  Stream<DjIncoming> get incoming => _incoming.stream;

  @override
  Stream<String> get participantJoined => _joined.stream;

  @override
  Stream<String> get participantLeft => _left.stream;

  @override
  bool isPresent(String identity) =>
      identity == selfIdentity ||
      room.remoteParticipants.containsKey(identity);

  @override
  Future<void> dispose() async {
    await _listener.dispose();
    await _incoming.close();
    await _joined.close();
    await _left.close();
    await _reconnected.close();
  }
}
