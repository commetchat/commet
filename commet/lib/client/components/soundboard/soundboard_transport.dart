// Transport seam for soundboard triggers.
//
// Primary: LiveKit data channel (reliable, topic chat.commet.soundboard.v1).
// Fallback: Matrix to-device (same envelope). Never timeline messages.
// Adapters live in matrix/components/soundboard/ (need flutter/matrix SDK).
import 'dart:async';

import 'soundboard_event.dart';

typedef SoundboardRemoteHandler = Future<void> Function(
  SoundboardEvent event, {
  String? authenticatedSenderId,
});

abstract class SoundboardTransport {
  /// Broadcast to other participants of THIS call only.
  Future<void> send(SoundboardEvent event);

  Stream<TransportIncoming> get incoming;

  Future<void> dispose();
}

class TransportIncoming {
  final SoundboardEvent event;

  /// Authenticated identity from the channel (LiveKit participant identity
  /// mapped to Matrix userId, or Matrix to-device sender). Receivers must
  /// prefer this over event.senderId.
  final String? authenticatedSenderId;

  const TransportIncoming(this.event, {this.authenticatedSenderId});
}

/// In-memory transport for unit/integration tests: connects N engines as
/// if they were participants of one call. Records latency instrumentation.
class InMemorySoundboardTransport implements SoundboardTransport {
  final String ownerId;
  final StreamController<TransportIncoming> _controller =
      StreamController<TransportIncoming>.broadcast();

  static final List<InMemorySoundboardTransport> _peers = [];

  /// Send/receive timestamps for latency measurement (test instrumentation).
  final List<int> sentAt = [];
  final List<int> receivedAt = [];

  InMemorySoundboardTransport(this.ownerId) {
    _peers.add(this);
  }

  @override
  Future<void> send(SoundboardEvent event) async {
    sentAt.add(DateTime.now().millisecondsSinceEpoch);
    // Microtask hop simulates network without real delay; tests can inject
    // artificial latency by wrapping.
    await Future.microtask(() {});
    for (final p in List.of(_peers)) {
      if (identical(p, this)) continue;
      p.receivedAt.add(DateTime.now().millisecondsSinceEpoch);
      p._controller.add(TransportIncoming(event,
          authenticatedSenderId: event.senderId));
    }
  }

  @override
  Stream<TransportIncoming> get incoming => _controller.stream;

  @override
  Future<void> dispose() async {
    _peers.remove(this);
    await _controller.close();
  }

  static void resetAll() => _peers.clear();
}
