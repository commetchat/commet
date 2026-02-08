import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/components/voip/webrtc_screencapture_source.dart';
import 'package:commet/client/components/voip/android_screencapture_source.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_stream.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_voip_room_component.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:matrix/matrix_api_lite.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class MatrixLivekitVoipSession implements VoipSession {
  MatrixRoom room;
  lk.Room livekitRoom;
  Timer? heartbeatTimer;
  String? heartbeatDelayId;

  final StreamController<void> _onVolumeChanged = StreamController.broadcast();

  MatrixLivekitVoipSession(this.room, this.livekitRoom) {
    clientManager?.callManager.onClientSessionStarted(this);
    addInitialStreams();

    final listener = livekitRoom.createListener();
    listener.on(onTrackPublished);
    listener.on(onTrackUnpublished);
    listener.on(onLocalTrackPublished);
    listener.on(onLocalTrackUnpublished);
    listener.on(onTrackStreamEvent);
    listener.on(onTrackMutedEvent);
    listener.on(onTrackUnmutedEvent);
    listener.on(onParticipantConnected);
    listener.on(onParticipantDisconnected);

    Timer.periodic(Duration(milliseconds: 200), (timer) {
      if (state == VoipState.ended) timer.cancel();
      _onVolumeChanged.add(());
    });

    startHeartbeat();
  }

  StreamController _stateChanged = StreamController.broadcast();
  final StreamController<VoipState> _onConnectionChanged =
      StreamController.broadcast();

  @override
  Stream<VoipState> get onConnectionStateChanged => _onConnectionChanged.stream;

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
        t.onStreamUpdatedEvent();
      }
    }
  }

  void onTrackMutedEvent(lk.TrackMutedEvent event) {
    if (event.publication.track?.mediaType ==
        RTCRtpMediaType.RTCRtpMediaTypeVideo) {
      streams.removeWhere((e) =>
          (e as MatrixLivekitVoipStream).publication.sid ==
          event.publication.sid);
    }

    for (var track in streams) {
      final t = track as MatrixLivekitVoipStream;
      if (t.publication.sid == event.publication.sid) {
        t.onStreamUpdatedEvent();
      }
    }

    print("Track muted");

    _stateChanged.add(());
  }

  void onTrackUnmutedEvent(lk.TrackUnmutedEvent event) {
    final participant =
        event.participant.identity.split(":").getRange(0, 2).join(":");

    for (var track in streams) {
      final t = track as MatrixLivekitVoipStream;
      if (t.publication.sid == event.publication.sid) {
        t.onStreamUpdatedEvent();
      }
    }

    if (streams.any((e) => e.streamId == event.publication.sid)) {
      return;
    }

    streams.add(MatrixLivekitVoipStream(event.publication, participant));
    _stateChanged.add(());
  }

  void onTrackPublished(lk.TrackPublishedEvent event) {
    final participant =
        event.participant.identity.split(":").getRange(0, 2).join(":");

    streams.add(MatrixLivekitVoipStream(event.publication, participant));
    _stateChanged.add(());
  }

  void onParticipantConnected(lk.ParticipantConnectedEvent event) {
    clientManager?.callManager.joinCallSound();
  }

  void onParticipantDisconnected(lk.ParticipantDisconnectedEvent event) {
    clientManager?.callManager.endCallSound();
  }

  void onLocalTrackPublished(lk.LocalTrackPublishedEvent event) {
    final participant =
        event.participant.identity.split(":").getRange(0, 2).join(":");

    streams.add(MatrixLivekitVoipStream(event.publication, participant));
    _stateChanged.add(());
  }

  void onLocalTrackUnpublished(lk.LocalTrackUnpublishedEvent event) {
    streams.removeWhere((e) =>
        (e as MatrixLivekitVoipStream).publication.sid ==
        event.publication.sid);

    _stateChanged.add(());
  }

  void onTrackUnpublished(lk.TrackUnpublishedEvent event) {
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
    Log.i("Hanging up call");

    await Future.wait([
      clearRoomCallState(),
      disconnectCall(),
      stopHeartbeat(),
    ]);

    state = VoipState.ended;
    _stateChanged.add(());
    _onConnectionChanged.add(state);

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
  Future<void> setMicrophoneMute(bool state) async {
    await livekitRoom.localParticipant?.setMicrophoneEnabled(!state);
    _stateChanged.add(());
  }

  @override
  Future<void> setScreenShare(ScreenCaptureSource source) async {
    if (source is WebrtcAndroidScreencaptureSource) {
      livekitRoom.localParticipant?.setScreenShareEnabled(true);
      Log.i("Got android screen capture source!");
      _stateChanged.add(());
      return;
    }

    final src = (source as WebrtcScreencaptureSource).source;

    var track = await lk.LocalVideoTrack.createScreenShareTrack(
        lk.ScreenShareCaptureOptions(
      sourceId: src.id,
      maxFrameRate: 30,
      params: lk.VideoParametersPresets.h1080_169,
    ));

    await livekitRoom.localParticipant?.publishVideoTrack(track);
    _stateChanged.add(());
  }

  @override
  Future<void> setCamera(MediaDeviceInfo? device) async {
    if (isCameraEnabled) {
      Log.e("Tried to enable camera when camera already enabled!");
      return;
    }

    await livekitRoom.localParticipant?.setCameraEnabled(true);
    _stateChanged.add(());
  }

  @override
  Future<void> stopCamera() async {
    await livekitRoom.localParticipant?.setCameraEnabled(false);

    _stateChanged.add(());
  }

  @override
  Future<void> stopScreenshare() async {
    await livekitRoom.localParticipant?.setScreenShareEnabled(false);

    if (PlatformUtils.isAndroid) {
      try {
        await FlutterBackground.disableBackgroundExecution();
      } catch (error) {
        Log.e('error disabling screen share: $error');
      }
    }

    _stateChanged.add(());
  }

  @override
  List<VoipStream> streams = List<VoipStream>.empty(growable: true);

  @override
  bool get supportsScreenshare => true;

  @override
  Future<void> updateStats() async {}

  @override
  Future<ScreenCaptureSource?> pickScreenCapture(BuildContext context) async {
    if (PlatformUtils.isAndroid) {
      return WebrtcAndroidScreencaptureSource.getCaptureSource(context);
    }
    return WebrtcScreencaptureSource.showSelectSourcePrompt(context);
  }

  Future<void> clearRoomCallState() async {
    Log.i("Clearing call state");
    final stateKey =
        "_${room.client.self!.identifier}_${room.matrixRoom.client.deviceID!}_m.call";

    await room.matrixRoom.client.setRoomStateWithKey(room.matrixRoom.id,
        MatrixVoipRoomComponent.callMemberStateEvent, stateKey, {});

    Log.i("Cleared call state");
  }

  Future<void> stopHeartbeat() async {
    heartbeatTimer?.cancel();
    heartbeatTimer = null;

    if (heartbeatDelayId == null) {
      return;
    }

    await room.matrixRoom.client.request(RequestType.POST,
        "/client/unstable/org.matrix.msc4140/delayed_events/${Uri.encodeComponent(heartbeatDelayId!)}",
        contentType: "application/json",
        data: jsonEncode({"action": "cancel"}));

    heartbeatDelayId = null;
    Log.i("Stopped heartbeat");
  }

  Future<void> startHeartbeat() async {
    final capabilities = await room.matrixRoom.client.getVersions();
    Log.d("${capabilities}");
    if (capabilities.unstableFeatures?["org.matrix.msc4140"] != true) {
      Log.e("Homeserver does not support delayed events");
      return;
    }

    final stateKey =
        "_${room.client.self!.identifier}_${room.matrixRoom.client.deviceID!}_m.call";

    final timerLength = Duration(seconds: 30);

    final result = await room.matrixRoom.client.request(RequestType.PUT,
        "/client/v3/rooms/${Uri.encodeComponent(room.matrixRoom.id)}/state/${Uri.encodeComponent(MatrixVoipRoomComponent.callMemberStateEvent)}/${Uri.encodeComponent(stateKey)}",
        contentType: "application/json",
        data: "{}",
        query: {
          "org.matrix.msc4140.delay": timerLength.inMilliseconds.toString()
        });

    final delayId = result["delay_id"] as String;
    heartbeatDelayId = delayId;

    heartbeatTimer =
        Timer.periodic(timerLength - Duration(seconds: 5), (timer) async {
      print("Sending heartbeat");
      final result = await room.matrixRoom.client.request(RequestType.POST,
          "/client/unstable/org.matrix.msc4140/delayed_events/${Uri.encodeComponent(delayId)}",
          contentType: "application/json",
          data: jsonEncode({"action": "restart"}));
      print(result);
    });
  }

  @override
  double get generalAudioLevel {
    double result =
        streams.fold(0.0, (value, stream) => max(value, stream.audiolevel));
    return result;
  }

  @override
  Stream<void> get onUpdateVolumeVisualizers => _onVolumeChanged.stream;

  Future<void> disconnectCall() async {
    Log.i("Disconnecting livekit room");
    await livekitRoom.disconnect();
    Log.i("Disconnected livekit room");
  }
}
