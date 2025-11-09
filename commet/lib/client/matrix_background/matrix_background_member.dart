import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/member.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:matrix_dart_sdk_drift_db/database.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:flutter/material.dart' as m;

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

  Future<void> init() async {
    var url = (event!.content["avatar_url"]);

    if (url is String) {
      var uri = Uri.parse(url);

      avatar = await uriToCachedMxcImageProvider(uri);

      Log.i("Got avatar: ${uri}");
    }
  }

  static Future<m.ImageProvider?> uriToCachedMxcImageProvider(Uri uri) async {
    var identifier = MatrixMxcImage.getThumbnailIdentifier(uri);

    Log.i("Looking for ${identifier} in file cache");
    var thumbnail = await fileCache?.getFile(identifier);

    if (thumbnail != null) {
      Log.i("Got file!");
      return m.Image.file(File(thumbnail.toString())).image;
    } else {
      Log.i("Missed thumbnail");
      var identifier = MatrixMxcImage.getIdentifier(uri);
      Log.i("Looking for ${identifier} in file cache");
      var file = await fileCache?.getFile(identifier);
      if (file != null) {
        Log.i("Got file!");
        return m.Image.file(File(file.toString())).image;
      } else {
        Log.i("Missed again");
      }
    }

    return null;
  }

  @override
  m.ImageProvider<Object>? avatar;

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

  @override
  // TODO: implement avatarId
  String? get avatarId => event!.content["avatar_url"] as String;
}
