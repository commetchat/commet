import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

class RTCDataMediaStream implements webrtc.MediaStream {
  late webrtc.RTCDataChannel channel;

  RTCDataMediaStream(this.channel);

  @override
  String get id => "${channel.id}_${channel.label}";

  @override
  String get ownerTag => throw UnimplementedError();

  @override
  Function(webrtc.MediaStreamTrack track)? onAddTrack;

  @override
  Function(webrtc.MediaStreamTrack track)? onRemoveTrack;

  @override
  bool? get active => throw UnimplementedError();

  @override
  Future<void> addTrack(webrtc.MediaStreamTrack track,
      {bool addToNative = true}) async {}

  @override
  Future<webrtc.MediaStream> clone() async {
    return this;
  }

  @override
  Future<void> dispose() {
    throw UnimplementedError();
  }

  @override
  List<webrtc.MediaStreamTrack> getAudioTracks() {
    return [];
  }

  @override
  Future<void> getMediaTracks() async {}

  @override
  webrtc.MediaStreamTrack? getTrackById(String trackId) {
    return null;
  }

  @override
  List<webrtc.MediaStreamTrack> getTracks() {
    return [];
  }

  @override
  List<webrtc.MediaStreamTrack> getVideoTracks() {
    return [];
  }

  @override
  Future<void> removeTrack(webrtc.MediaStreamTrack track,
      {bool removeFromNative = true}) async {}
}
