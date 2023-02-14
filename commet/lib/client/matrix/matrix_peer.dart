import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';

class MatrixPeer implements Peer {
  @override
  ImageProvider<Object>? avatar;

  @override
  Client client;

  @override
  String displayName;

  @override
  String identifier;

  MatrixPeer(this.client, this.identifier, this.displayName, this.avatar);
}
