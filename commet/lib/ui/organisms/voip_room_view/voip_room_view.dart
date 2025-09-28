import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip_room/voip_room_component.dart';
import 'package:commet/ui/organisms/call_view/call.dart';
import 'package:commet/ui/organisms/call_view/call_view.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class VoipRoomView extends StatefulWidget {
  final VoipRoomComponent voip;
  const VoipRoomView(this.voip, {super.key});

  @override
  State<VoipRoomView> createState() => _VoipRoomViewState();
}

class _VoipRoomViewState extends State<VoipRoomView> {
  VoipSession? currentSession;

  @override
  void initState() {
    currentSession = widget.voip.currentSession;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (currentSession == null)
      return Column(
        children: [
          tiamat.Button(
            text: "Join",
            onTap: joinRoomCall,
          ),
        ],
      );

    return CallWidget(currentSession!);
  }

  joinRoomCall() async {
    final session = await widget.voip.joinCall();
    if (session != null) {
      setState(() {
        currentSession = session;
      });
    }
  }
}
