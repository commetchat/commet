import 'dart:async';

import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_session.dart';
import 'package:commet/utils/list_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:matrix/matrix.dart';

class MatrixVoipStream implements VoipStream {
  WrappedMediaStream stream;
  MatrixVoipSession session;

  RTCVideoRenderer? renderer;

  StreamController _onChanged = StreamController.broadcast();

  @override
  Stream<void> get onStreamChanged => _onChanged.stream;

  MatrixVoipStream(this.stream, this.session) {
    initRenderer();
    stream.onStreamChanged.stream.listen(_onStreamChanged);
  }

  void _onStreamChanged(MediaStream event) {
    if (renderer != null) {
      renderer!.srcObject = event;
    } else {
      initRenderer();
    }

    _onChanged.add(());
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
    print(stat.values["audioLevel"]);
    return stat.values["audioLevel"] > 0.2 ? 1.0 : 0;
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
      return CircularProgressIndicator();
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

  @override
  VoipStreamDirection get direction => stream.isLocal()
      ? VoipStreamDirection.outgoing
      : VoipStreamDirection.incoming;
}
