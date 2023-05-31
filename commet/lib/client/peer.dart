import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';

abstract class Peer {
  late String identifier;
  late String userName;
  late String displayName;
  late Client client;
  String? detail;
  ImageProvider? avatar;
}
