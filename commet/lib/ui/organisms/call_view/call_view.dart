import 'dart:async';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/ui/organisms/call_view/voip_stream_view.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class CallView extends StatefulWidget {
  const CallView(this.currentSession, {super.key});
  final VoipSession currentSession;

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> {
  Timer? statTimer;

  @override
  void initState() {
    super.initState();

    statTimer = Timer.periodic(const Duration(milliseconds: 500), timer);
  }

  @override
  void dispose() {
    statTimer?.cancel();
    super.dispose();
  }

  void timer(Timer timer) async {
    widget.currentSession.updateStats();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      itemBuilder: (context, index) {
        var stream = widget.currentSession.streams[index];

        return tiamat.Tile.low3(
            child: VoipStreamView(stream, widget.currentSession));
      },
      itemCount: widget.currentSession.streams.length,
    );
  }
}
