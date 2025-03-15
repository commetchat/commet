import 'dart:async';

import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_session.dart';
import 'package:commet/utils/list_extension.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:matrix/matrix.dart';

class MatrixVoipStream implements VoipStream {
  WrappedMediaStream stream;
  MatrixVoipSession session;

  RTCVideoRenderer? renderer;

  MatrixVoipStream(this.stream, this.session) {
    initRenderer();
    stream.onStreamChanged.stream.listen(onStreamChanged);
  }

  void onStreamChanged(MediaStream event) {
    if (renderer != null) {
      renderer!.srcObject = event;
    } else {
      initRenderer();
    }
  }

  Future<void> initRenderer() async {
    if (stream.stream?.getVideoTracks().isNotEmpty == true) {
      var r = RTCVideoRenderer();
      await r.initialize();
      r.srcObject = stream.stream!;

      renderer = r;
    }
  }

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
  String get streamUserId => stream.participant.userId;

  @override
  String get label => stream.stream?.getTracks().first.label ?? "";

  @override
  double get audiolevel {
    var tracks = stream.stream?.getAudioTracks();
    var track = tracks?.firstOrNull;

    if (track == null) {
      return 0;
    }

    var stats = session.stats;

    if (stats == null) {
      return 0;
    }

    var stat = stats.tryFirstWhere((element) {
      if (element.values.containsKey("trackIdentifier") == false) {
        return false;
      }

      if (element.values.containsKey("audioLevel") == false) {
        return false;
      }

      return element.values["trackIdentifier"] == track.id;
    });

    if (stat == null) return 0;

    return stat.values["audioLevel"];
  }

  @override
  double? get aspectRatio {
    if (renderer != null) {
      final width = renderer!.videoWidth;
      final height = renderer!.videoHeight;
      if (width > 0 && height > 0) {
        var ratio = renderer!.videoWidth / renderer!.videoHeight;
        return ratio;
      }
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
  Widget? buildVideoRenderer(BoxFit fit, Key key) {
    if (renderer == null) {
      return const Placeholder();
    }

    if (fit == BoxFit.contain) {
      return AspectRatio(
          aspectRatio: aspectRatio ?? 1, child: RTCVideoView(renderer!));
    } else {
      if (renderer!.textureId != null) {
        return RTCVideoView(
          key: key,
          renderer!,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        );
      }
    }

    return null;
  }
}
