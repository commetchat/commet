import 'dart:math';

import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/painting/box_fit.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:livekit_client/livekit_client.dart';

class MatrixLivekitVoipStream implements VoipStream {
  TrackPublication publication;
  String userId;

  AudioVisualizer? visualizer;

  MatrixLivekitVoipStream(this.publication, this.userId) {
    if (publication.track is AudioTrack) {
      visualizer = createVisualizer(publication.track as AudioTrack,
          options:
              AudioVisualizerOptions(barCount: 1, smoothTransition: false));

      var _listener = visualizer!.createListener();
      _listener.on<AudioVisualizerEvent>((e) {
        audiolevel = (e.event[0] as double) * 4;
      });

      visualizer!.start();
    }
  }

  @override
  double? get aspectRatio {
    if (publication.dimensions == null) {
      return null;
    }
    return publication.dimensions!.width.toDouble() /
        publication.dimensions!.height.toDouble();
  }

  @override
  double audiolevel = 0.0;

  @override
  Widget? buildVideoRenderer(BoxFit fit, Key key) {
    if (publication.track is RemoteVideoTrack) {
      return VideoTrackRenderer(publication.track as VideoTrack);
    }

    return null;
  }

  @override
  // TODO: implement direction
  VoipStreamDirection get direction => VoipStreamDirection.incoming;

  @override
  String get label => "label";

  @override
  // TODO: implement streamId
  String get streamId => publication.sid;

  @override
  // TODO: implement streamUserId
  String get streamUserId => userId;

  @override
  // TODO: implement type
  VoipStreamType get type {
    if (publication.track is AudioTrack) {
      return VoipStreamType.audio;
    }

    if (publication.isScreenShare) {
      return VoipStreamType.screenshare;
    }

    return VoipStreamType.video;
  }
}
