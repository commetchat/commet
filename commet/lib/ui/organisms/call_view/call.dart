import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/ui/organisms/call_view/call_view.dart';
import 'package:commet/ui/organisms/call_view/screen_capture_source_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:tiamat/atoms/popup_dialog.dart';

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
    );
  }

  Future<void> pickScreenShareSource() async {
    var sources = await desktopCapturer
        .getSources(types: [SourceType.Window, SourceType.Screen]);

    if (context.mounted) {
      var result = await PopupDialog.show<DesktopCapturerSource>(
          // ignore: use_build_context_synchronously
          context,
          content: ScreenCaptureSourceDialog(sources),
          title: "Screen Share");
      if (result != null) {
        await widget.session.setScreenShare(result);
        setState(() {});
      }
    }
  }

  Future<void> stopScreenshare() {
    return widget.session.stopScreenshare();
  }

  Future<void> setMicrophoneMute(bool isMuted) {
    return widget.session.setMicrophoneMute(isMuted);
  }

  Future<void> pickCamera() async {
    var devices = await navigator.mediaDevices.enumerateDevices();
    devices = devices.where((element) => element.kind == "videoinput").toList();

    if (devices.length == 1) {
      widget.session.setCamera(devices.first);
    } else {}
  }

  Future<void> hangUp() {
    return widget.session.hangUpCall();
  }

  Future<void> disableCamera() {
    return widget.session.stopCamera();
  }
}
