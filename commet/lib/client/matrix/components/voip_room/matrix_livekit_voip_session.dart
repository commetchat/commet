import 'dart:async';
import 'dart:io';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/components/voip/webrtc_screencapture_source.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_android_screencapture_source.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_stream.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_voip_room_component.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_interface/src/mediadevices.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class MatrixLivekitVoipSession implements VoipSession {
  MatrixRoom room;
  lk.Room livekitRoom;
  MatrixLivekitVoipSession(this.room, this.livekitRoom) {
    clientManager?.callManager.onClientSessionStarted(this);
    addInitialStreams();

    final listener = livekitRoom.createListener();
    listener.on(onTrackPublished);
    listener.on(onTrackUnpublished);
    listener.on(onTrackStreamEvent);
  }

  StreamController _stateChanged = StreamController.broadcast();

  void addInitialStreams() {
    if (livekitRoom.localParticipant != null) {
      for (var entry
          in livekitRoom.localParticipant!.trackPublications.entries) {
        if (entry.value.muted && entry.value.kind == lk.TrackType.VIDEO) {
          continue;
        }

        streams.add(
            MatrixLivekitVoipStream(entry.value, room.client.self!.identifier));
      }
    }

    for (var entry in livekitRoom.remoteParticipants.entries) {
      for (var stream in entry.value.trackPublications.entries) {
        if (stream.value.kind == lk.TrackType.VIDEO && stream.value.muted) {
          continue;
        }

        String userId = entry.key;
        userId = userId.split(":").getRange(0, 2).join(":");

        streams.add(MatrixLivekitVoipStream(stream.value, userId));
      }
    }
  }

  @override
  Future<void> acceptCall(
      {bool withMicrophone = false, bool withCamera = false}) {
    throw UnimplementedError();
  }

  void onTrackStreamEvent(lk.TrackStreamStateUpdatedEvent event) {
    for (var track in streams) {
      final t = track as MatrixLivekitVoipStream;
      if (t.publication.sid == event.publication.sid) {
        t.onStreamUpdatedEvent(event);
      }
    }
    print("Received track event: ${event}");
  }

  void onTrackPublished(lk.TrackPublishedEvent event) {
    print("Received new track: ${event}");

    final participant =
        event.participant.identity.split(":").getRange(0, 2).join(":");

    print("From peer: ${participant}");

    streams.add(MatrixLivekitVoipStream(event.publication, participant));
    _stateChanged.add(());
  }

  void onTrackUnpublished(lk.TrackUnpublishedEvent event) {
    print(
      "Track unpublished: $event",
    );

    streams.removeWhere((e) =>
        (e as MatrixLivekitVoipStream).publication.sid ==
        event.publication.sid);

    _stateChanged.add(());
  }

  @override
  Client get client => room.client;

  @override
  VoipState state = VoipState.connected;

  @override
  Future<void> declineCall() {
    throw UnimplementedError();
  }

  @override
  Future<void> hangUpCall() async {
    final stateKey =
        "_${room.client.self!.identifier}_${room.matrixRoom.client.deviceID!}_m.call";

    await Future.wait([
      livekitRoom.disconnect(),
      room.matrixRoom.client.setRoomStateWithKey(room.matrixRoom.id,
          MatrixVoipRoomComponent.callMemberStateEvent, stateKey, {})
    ]);

    state = VoipState.ended;
    _stateChanged.add(());

    clientManager?.callManager.onSessionEnded(this);
  }

  @override
  bool get isCameraEnabled =>
      livekitRoom.localParticipant?.isCameraEnabled() ?? false;

  @override
  bool get isMicrophoneMuted => livekitRoom.localParticipant?.isMuted ?? false;

  @override
  bool get isSharingScreen =>
      livekitRoom.localParticipant?.isScreenShareEnabled() ?? false;

  @override
  Stream<void> get onStateChanged => _stateChanged.stream;

  @override
  String? get remoteUserId => null;

  @override
  VoipStream? get remoteUserMediaStream => null;

  @override
  String? get remoteUserName => null;

  @override
  String get roomId => room.identifier;

  @override
  String get roomName => room.displayName;

  @override
  String get sessionId => "";

  @override
  Future<void> setCamera(MediaDeviceInfo? device) async {
    await livekitRoom.localParticipant?.setCameraEnabled(true);
  }

  @override
  Future<void> setMicrophoneMute(bool state) async {
    await livekitRoom.localParticipant?.setMicrophoneEnabled(!state);
  }

  @override
  Future<void> setScreenShare(ScreenCaptureSource source) async {
    if (source is MatrixLivekitAndroidScreencaptureSource) {
      livekitRoom.localParticipant?.setScreenShareEnabled(true);
      Log.i("Got android screen capture source!");
      return;
    }

    final src = (source as WebrtcScreencaptureSource).source;
    var track = await lk.LocalVideoTrack.createScreenShareTrack(
      lk.ScreenShareCaptureOptions(
          sourceId: src.id,
          maxFrameRate: 30.0,
          params: lk.VideoParametersPresets.screenShareH1080FPS30),
    );

    await livekitRoom.localParticipant?.publishVideoTrack(track);
  }

  @override
  Future<void> stopCamera() async {
    await livekitRoom.localParticipant?.setCameraEnabled(false);
  }

  @override
  Future<void> stopScreenshare() async {
    await livekitRoom.localParticipant?.setScreenShareEnabled(false);

    if (PlatformUtils.isAndroid) {
      try {
        await FlutterBackground.disableBackgroundExecution();
      } catch (error) {
        print('error disabling screen share: $error');
      }
    }
  }

  @override
  List<VoipStream> streams = List<VoipStream>.empty(growable: true);

  @override
  bool get supportsScreenshare => true;

  @override
  Future<void> updateStats() async {}

  @override
  Future<ScreenCaptureSource?> pickScreenCapture(BuildContext context) async {
    if (Platform.isAndroid) {
      return MatrixLivekitAndroidScreencaptureSource.getCaptureSource(context);
    }
    return WebrtcScreencaptureSource.showSelectSourcePrompt(context);
  }
}
