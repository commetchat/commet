// Matrix to-device fallback transport.
//
// Used when LiveKit is unavailable (e.g. 1:1 Matrix-VoIP calls, or SFU data
// channel unsupported). Same SoundboardEvent envelope; type
// `chat.commet.soundboard.play`. To-device is ephemeral (no timeline
// pollution) and E2EE-encrypted when the account uses encryption.
//
// Latency is higher than LiveKit data channel (sync round-trip), so this is
// strictly a fallback — LivekitSoundboardTransport is preferred whenever a
// LiveKit room is connected.
import 'dart:async';
import 'dart:convert';

import 'package:commet/client/components/soundboard/soundboard_event.dart';
import 'package:commet/client/components/soundboard/soundboard_transport.dart';
import 'package:commet/debug/log.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixToDeviceSoundboardTransport implements SoundboardTransport {
  final matrix.Client mx;
  final String roomId;

  final StreamController<TransportIncoming> _controller =
      StreamController<TransportIncoming>.broadcast();
  StreamSubscription? _sub;

  MatrixToDeviceSoundboardTransport(this.mx, {required this.roomId}) {
    _sub = mx.onToDeviceEvent.stream
        .where((e) => e.type == SoundboardEvent.toDeviceType)
        .listen((e) {
      try {
        final content = Map<String, dynamic>.from(e.content);
        // Scope check: only triggers for THIS call's room.
        if (content['room_id'] != roomId) return;
        final payload = content['payload'];
        if (payload is! Map) return;
        final event =
            SoundboardEvent.tryParse(Map<String, dynamic>.from(payload));
        if (event == null) return;
        _controller
            .add(TransportIncoming(event, authenticatedSenderId: e.sender));
      } catch (err, s) {
        Log.onError(err, s, content: 'Soundboard to-device parse failed');
      }
    });
  }

  @override
  Future<void> send(SoundboardEvent event) async {
    // To-device goes to other call participants only (scoped by roomId in
    // the payload; receivers drop mismatched room_id). Failures are
    // non-fatal: the caller already played locally, so we log and return —
    // never block the user with modals.
    try {
      final content = {
        'room_id': roomId,
        'payload': event.toJson(),
      };
      // Collect target devices from current call memberships (same source
      // the LiveKit E2EE key provider uses), so only THIS call's
      // participants are notified — never the whole Space.
      final room = mx.getRoomById(roomId);
      final memberStates =
          room?.states['org.matrix.msc3401.call.member'] as Map?;
      final deviceKeys = <matrix.DeviceKeys>[];
      final userIds = <String>{};
      if (memberStates != null) {
        for (final ev in memberStates.values) {
          if (ev is! matrix.StrippedStateEvent) continue;
          final stateEv = ev;
          if (stateEv.content.isEmpty) continue;
          final sender = stateEv.senderId;
          final device = (stateEv.content['device_id'] as String?) ?? '';
          if (sender.isEmpty || sender == mx.userID) continue;
          userIds.add(sender);
          if (device.isNotEmpty) {
            final dk = mx.userDeviceKeys[sender]?.deviceKeys[device];
            if (dk != null) deviceKeys.add(dk);
          }
        }
      }
      if (deviceKeys.isNotEmpty && mx.encryptionEnabled) {
        await mx.sendToDeviceEncrypted(
            deviceKeys, SoundboardEvent.toDeviceType, content);
        return;
      }
      if (userIds.isNotEmpty) {
        // Unencrypted fallback (rooms without E2EE): plain to-device.
        final messages = <String, Map<String, Map<String, dynamic>>>{};
        for (final u in userIds) {
          messages[u] = {
            '*': content,
          };
        }
        await mx.sendToDevice(SoundboardEvent.toDeviceType,
            DateTime.now().millisecondsSinceEpoch.toString(), messages);
      }
    } catch (e, s) {
      Log.onError(e, s, content: 'Soundboard to-device send failed');
    }
  }

  /// Encodes content without sending (unit-test seam).
  static Map<String, dynamic> encodeForRoom(
      SoundboardEvent event, String roomId) {
    return {
      'room_id': roomId,
      'payload': event.toJson(),
      'raw': jsonEncode(event.toJson()),
    };
  }

  @override
  Stream<TransportIncoming> get incoming => _controller.stream;

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }
}
