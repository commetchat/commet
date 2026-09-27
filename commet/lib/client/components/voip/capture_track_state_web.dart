// ignore: depend_on_referenced_packages
import 'package:dart_webrtc/dart_webrtc.dart' show MediaStreamTrackWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

bool captureTrackEnded(rtc.MediaStreamTrack track) =>
    track is MediaStreamTrackWeb && track.jsTrack.readyState == 'ended';
