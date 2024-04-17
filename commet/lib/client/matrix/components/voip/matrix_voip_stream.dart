import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_session.dart';
import 'package:commet/utils/list_extension.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:matrix/matrix.dart';

class MatrixVoipStream implements VoipStream {
  WrappedMediaStream stream;
  MatrixVoipSession session;

  MatrixVoipStream(this.stream, this.session);

  @override
  VoipStreamType get type {
    if (stream.purpose == SDPStreamMetadataPurpose.Screenshare) {
      return VoipStreamType.screenshare;
    }

    if (stream.videoMuted) {
      return VoipStreamType.audio;
    } else {
      return VoipStreamType.video;
    }
  }

  @override
  String get streamUserId => stream.userId;

  @override
  String get label => stream.stream?.getTracks().first.label ?? "";

  @override
  double get audiolevel {
    var stats = session.stats;

    if (stats == null) {
      return 0;
    }

    var tracks = stream.stream?.getAudioTracks();
    var track = tracks?.first;

    var stat = stats.tryFirstWhere((element) {
      if (element.values.containsKey("trackIdentifier") == false) {
        return false;
      }

      if (element.values.containsKey("audioLevel") == false) {
        return false;
      }

      return element.values["trackIdentifier"] == track?.id;
    });

    if (stat == null) return 0;

    return stat.values["audioLevel"];
  }

  @override
  double? get aspectRatio {
    var ratio = stream.renderer.videoWidth / stream.renderer.videoHeight;
    if (ratio > 0) {
      return ratio;
    }

    return 1;
  }

  @override
  String get streamId => stream.stream?.id ?? "UNKNOWN_STREAM_ID";

  @override
  bool operator ==(Object other) {
    if (other is! MatrixVoipStream) return false;
    return streamId == other.streamId;
  }

  @override
  int get hashCode => streamId.hashCode;

  @override
  Widget? buildVideoRenderer(BoxFit fit) {
    if (fit == BoxFit.contain) {
      return AspectRatio(
          aspectRatio: aspectRatio ?? 1,
          child: RTCVideoView(stream.renderer as RTCVideoRenderer));
    } else {
      if (stream.renderer.textureId != null) {
        return RTCVideoView(
          stream.renderer as RTCVideoRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        );
      }
    }

    return null;
  }
}
