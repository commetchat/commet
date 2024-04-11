import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/voip/voip_component.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_plugin.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_timeline_event.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/ui/atoms/generic_room_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:matrix/matrix.dart';

class MatrixVoipComponent
    implements VoipComponent<MatrixClient>, EventHandlerComponent {
  @override
  MatrixClient client;

  late VoIP voip;

  late MatrixVoipPlugin plugin;

  MatrixVoipComponent(this.client) {
    plugin = MatrixVoipPlugin();
    voip = VoIP(client.getMatrixClient(), plugin);
  }

  @override
  bool canHandleEvent(TimelineEvent event) {
    if (event is! MatrixTimelineEvent) {
      return false;
    }

    return [EventTypes.CallHangup, EventTypes.CallInvite, EventTypes.CallReject]
        .contains(event.event.type);
  }

  @override
  Widget? displayTimelineEvent(TimelineEvent event,
      {required String senderName}) {
    if (event is! MatrixTimelineEvent) {
      return null;
    }

    switch (event.event.type) {
      case EventTypes.CallHangup:
        return GenericRoomEvent(
          "$senderName left the call",
          icon: Icons.call_end,
        );
      case EventTypes.CallReject:
        return GenericRoomEvent(
          "$senderName rejected the call",
          icon: Icons.call_end,
        );
      case EventTypes.CallInvite:
        return GenericRoomEvent(
          "$senderName started a call",
          icon: Icons.call_end,
        );
    }

    return Text(event.event.type);
  }
}
