import 'dart:async';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/ui/organisms/call_view/call_view.dart';
import 'package:flutter/cupertino.dart';

class CallWidget extends StatefulWidget {
  const CallWidget(this.session, {super.key});
  final VoipSession session;

  @override
  State<CallWidget> createState() => _CallWidgetState();
}

class _CallWidgetState extends State<CallWidget> {
  @override
  Widget build(BuildContext context) {
    return CallView(
      widget.session,
      pickScreenshareSource: pickScreenShareSource,
      stopScreenshare: stopScreenshare,
      setMicrophoneMute: setMicrophoneMute,
      pickCamera: pickCamera,
      disableCamera: disableCamera,
      hangUp: hangUp,
      declineCall: declineCall,
      acceptCall: acceptCall,
    );
  }

  Future<void> pickScreenShareSource() async {
    final source = await widget.session.pickScreenCapture(context);
    if (source != null) {
      widget.session.setScreenShare(source);
    }
  }

  Future<void> stopScreenshare() {
    return widget.session.stopScreenshare();
  }

  Future<void> setMicrophoneMute(bool isMuted) {
    return widget.session.setMicrophoneMute(isMuted);
  }

  Future<void> pickCamera() async {
    // there doesnt seem to be a clear way to allow matrix-dart-sdk to insert a stream from a specific camera,
    // because it calls `_getUserMedia` internally to pick a camera, so we use null here
    widget.session.setCamera(null);
  }

  Future<void> hangUp() {
    return widget.session.hangUpCall();
  }

  Future<void> disableCamera() {
    return widget.session.stopCamera();
  }

  Future<void> declineCall() {
    return widget.session.declineCall();
  }

  Future<void> acceptCall() {
    return widget.session.acceptCall();
  }
}
