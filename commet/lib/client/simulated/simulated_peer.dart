import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';

class SimulatedPeer extends Peer {
  SimulatedPeer(Client client, String identifier, String displayName,
      ImageProvider? avatar) {
    this.client = client;
    this.identifier = identifier;
    this.displayName = displayName;
    this.avatar = avatar;
    userName = displayName;
    detail = "simulated";
  }

  @override
  Color get defaultColor => Colors.redAccent;
}
