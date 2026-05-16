import 'dart:async';

import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';

class MatrixLivekitVoipStream implements VoipStream {
  TrackPublication publication;
  String userId;

  AudioVisualizer? visualizer;

  StreamController _onChanged = StreamController.broadcast();

  @override
  Stream<void> get onStreamChanged => _onChanged.stream;

  MatrixLivekitVoipStream(this.publication, this.userId) {
    if (publication.track case AudioTrack t) {
      visualizer = createVisualizer(t,
          options:
              AudioVisualizerOptions(barCount: 1, smoothTransition: false));

      var volume = preferences.getVoipUserVolume(userId);
      Helper.setVolume(volume, t.mediaStreamTrack);

      var _listener = visualizer!.createListener();
      _listener.on<AudioVisualizerEvent>((e) {
        setAudioLevel(e);
      });

      visualizer!.start();
    }
  }

  @override
  double audiolevel = 0.0;

  void setAudioLevel(AudioVisualizerEvent e) {
    audiolevel = (e.event[0] as double) > 0.5 ? 1 : 0;
  }

  void onStreamUpdatedEvent() {
    _onChanged.add(());
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
  Widget? buildVideoRenderer(BoxFit fit, Key key) {
    if (publication.track is VideoTrack) {
      return VideoTrackRenderer(publication.track as VideoTrack);
    }

    return null;
  }

  @override
  VoipStreamDirection get direction => publication is LocalTrackPublication
      ? VoipStreamDirection.outgoing
      : VoipStreamDirection.incoming;

  @override
  String get label => "label";

  @override
  String get streamId => publication.sid;

  @override
  String get streamUserId => userId;

  @override
  VoipStreamType get type {
    if (publication.track is AudioTrack) {
      return VoipStreamType.audio;
    }

    if (publication.isScreenShare) {
      return VoipStreamType.screenshare;
    }

    return VoipStreamType.video;
  }

  @override
  bool get isMuted => publication.track?.muted ?? false;

  @override
  Future<void> setVolume(double volume) async {
    preferences.setVoipUserVolume(userId, volume);
    if (publication.track case AudioTrack track) {
      Helper.setVolume(volume, track.mediaStreamTrack);
    }
  }

  @override
  double get volume => preferences.getVoipUserVolume(userId);
}
