import 'dart:async';

import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_session.dart';
import 'package:commet/main.dart';
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
    setVolume(preferences.getVoipUserVolume(streamUserId));
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
      // COMMET: views built before the renderer existed (e.g. the voice
      // panel's live preview) need to know there is now something to draw.
      _onChanged.add(());
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

    // COMMET: each view gets its own renderer instead of sharing [renderer].
    // The same stream can be on screen twice (call view + the voice panel's
    // live preview) and on web an RTCVideoView owns the renderer's single
    // <video> element, so two views on one renderer fight over it.
    return _MatrixVideoView(this, fit: fit, key: key);
  }

  @override
  VoipStreamDirection get direction => stream.isLocal()
      ? VoipStreamDirection.outgoing
      : VoipStreamDirection.incoming;

  @override
  bool get isMuted => stream.audioMuted;

  @override
  bool get isDeafened => false;

  @override
  // TODO: implement stats
  String get stats => session.stats.toString();

  @override
  Future<void> setVolume(double volume) async {
    preferences.setVoipUserVolume(streamUserId, volume);

    var tracks = stream.stream?.getAudioTracks();

    if (tracks != null) {
      for (var track in tracks) {
        await Helper.setVolume(volume, track);
      }
    }
  }

  @override
  double get volume => preferences.getVoipUserVolume(streamUserId);
}

/// Renders a [MatrixVoipStream] with a renderer owned by this view, mirroring
/// how LiveKit's `VideoTrackRenderer` works. Disposed with the view.
class _MatrixVideoView extends StatefulWidget {
  const _MatrixVideoView(this.stream, {required this.fit, super.key});
  final MatrixVoipStream stream;
  final BoxFit fit;

  @override
  State<_MatrixVideoView> createState() => _MatrixVideoViewState();
}

class _MatrixVideoViewState extends State<_MatrixVideoView> {
  RTCVideoRenderer? _renderer;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.stream.onStreamChanged.listen((_) {
      final source = widget.stream.stream.stream;
      if (_renderer != null && source != null) {
        _renderer!.srcObject = source;
      }
      if (mounted) setState(() {});
    });
    _init();
  }

  Future<void> _init() async {
    final r = RTCVideoRenderer();
    await r.initialize();
    if (!mounted) {
      await r.dispose();
      return;
    }
    r.srcObject = widget.stream.stream.stream;
    setState(() => _renderer = r);
  }

  @override
  void dispose() {
    _sub?.cancel();
    final r = _renderer;
    _renderer = null;
    if (r != null) {
      r.srcObject = null;
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _renderer;
    if (r == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.fit == BoxFit.contain) {
      return AspectRatio(
          aspectRatio: widget.stream.aspectRatio ?? 1, child: RTCVideoView(r));
    }

    return RTCVideoView(
      r,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }
}
