import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';

abstract class Peer {
  late String identifier;
  late String detail;
  late String userName;
  late String displayName;
  late ImageProvider? avatar;
  late Client client;
  late Color? color;
}
