import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';

abstract class Peer {
  late String identifier;
  late String displayName;
  late ImageProvider? avatar = null;
  late Client client;
}
