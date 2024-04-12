import 'dart:async';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/peer.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class VoipStreamView extends StatefulWidget {
  const VoipStreamView(this.stream, this.session, {super.key});
  final VoipStream stream;
  final VoipSession session;

  @override
  State<VoipStreamView> createState() => _VoipStreamViewState();
}

class _VoipStreamViewState extends State<VoipStreamView>
    with TickerProviderStateMixin {
  late Peer user;

  late AnimationController audioLevel;

  @override
  void initState() {
    Timer.periodic(const Duration(milliseconds: 500), timer);

    user = widget.session.client.getPeer(widget.stream.streamUserId);
    audioLevel = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    super.initState();
  }

  void timer(Timer timer) async {
    audioLevel.animateTo(widget.stream.audiolevel);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: audioLevel,
        builder: (context, child) {
          return Stack(
            children: [buildDefault(), tiamat.Text("${audioLevel.value}")],
          );
        });
  }

  Widget buildDefault() {
    switch (widget.stream.type) {
      case VoipStreamType.audio:
        return Center(
            child: tiamat.Avatar(
                border: Border.all(
                    strokeAlign: BorderSide.strokeAlignOutside,
                    color: getBorderColor(context),
                    width: audioLevel.value * 5),
                radius: 50,
                image: user.avatar,
                placeholderText: user.displayName));

      case VoipStreamType.video:
      case VoipStreamType.screenshare:
        return widget.stream.videoRender ?? const Placeholder();
    }
  }

  Color getBorderColor(BuildContext context) {
    return Color.lerp(Theme.of(context).primaryColor,
        Theme.of(context).colorScheme.primary, audioLevel.value)!;
  }
}
