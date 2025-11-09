import 'dart:convert';
import 'dart:ui';

import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/member.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter/src/painting/image_provider.dart';
import 'package:matrix_dart_sdk_drift_db/database.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixBackgroundMember implements Member {
  RoomMember? data;

  matrix.BasicEvent? event;

  @override
  String identifier;

  MatrixBackgroundMember(this.identifier, {this.data}) {
    if (data != null) {
      event = matrix.BasicEvent.fromJson(jsonDecode(data!.content));
    }
  }

  @override
  ImageProvider<Object>? get avatar => null;

  @override
  Color get defaultColor => MatrixPeer.hashColor(identifier);

  @override
  String? get detail => "";

  @override
  String get displayName {
    if (event != null) {
      Log.i("Got user data: ${data!.content}");
      return event!.content["displayname"] as String;
    }

    return identifier;
  }

  @override
  String get userName => identifier;
}
