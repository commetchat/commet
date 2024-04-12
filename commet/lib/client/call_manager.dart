import 'dart:async';

import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/voip/voip_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/stale_info.dart';
import 'package:commet/utils/notifying_list.dart';

class CallManager {
  ClientManager clientManager;
  final StreamController<VoipSession> _onSessionStarted =
      StreamController.broadcast();

  Stream<VoipSession> get onSessionStarted => _onSessionStarted.stream;

  NotifyingList<VoipSession> currentSessions =
      NotifyingList.empty(growable: true);

  CallManager(this.clientManager) {
    clientManager.onClientAdded.stream.listen(_onClientAdded);
    clientManager.onClientRemoved.stream.listen(_onClientRemoved);
  }

  void _onClientAdded(int index) {
    var client = clientManager.clients[index];

    var voip = client.getComponent<VoipComponent>();
    if (voip == null) {
      return;
    }

    voip.onSessionStarted.listen(_onClientSessionStarted);
    voip.onSessionEnded.listen(_onSessionEnded);
  }

  void _onClientRemoved(StalePeerInfo event) {}

  void _onClientSessionStarted(VoipSession event) {
    currentSessions.add(event);
  }

  void _onSessionEnded(VoipSession event) {
    currentSessions
        .removeWhere((element) => element.sessionId == event.sessionId);
  }
}
