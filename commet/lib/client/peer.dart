import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';

abstract class Peer {
  late String identifier;
  late String? detail = null;
  late String userName;
  late String displayName;
  late ImageProvider? avatar = null;
  late Client client;
  late Color? color = null;
}
