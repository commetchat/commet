import 'package:commet/client/components/voip/voip_stream.dart';

/// One tile of the call grid.
///
/// [audioStream] is the screen share audio that goes with a
/// [VoipStreamType.screenshare] tile, when the sharer captures system audio.
/// It is what the tile's volume control drives.
class CallGridTile {
  final VoipStream stream;
  final VoipStream? audioStream;

  const CallGridTile(this.stream, {this.audioStream});
}

/// Picks which of a session's [streams] get a tile and pairs screen share
/// audio with its member's screen share. Screen share audio never gets a tile
/// of its own, so a member sharing their screen with audio shows up as one
/// avatar plus one screen share, not two avatars.
List<CallGridTile> callGridTiles(Iterable<VoipStream> streams) {
  // By the publishing device, not by user: someone in the call from two
  // devices has the same user id on both, and each share's audio belongs to
  // the tile of that device.
  final screenAudioByUser = <String, VoipStream>{
    for (final s in streams)
      if (s.type == VoipStreamType.screenshareAudio) s.streamOwnerId: s
  };

  return [
    for (final s in streams)
      if (s.type != VoipStreamType.screenshareAudio &&
          s.type != VoipStreamType.music)
        CallGridTile(s,
            audioStream: s.type == VoipStreamType.screenshare
                ? screenAudioByUser[s.streamOwnerId]
                : null)
  ];
}
