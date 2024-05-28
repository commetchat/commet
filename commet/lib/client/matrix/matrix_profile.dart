import 'dart:ui';

import 'package:commet/client/matrix/matrix_member.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/profile.dart';
import 'package:flutter/src/painting/image_provider.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixProfile implements Profile {
  matrix.Profile profile;
  matrix.Client client;

  @override
  ImageProvider<Object>? get avatar => profile.avatarUrl != null
      ? MatrixMxcImage(profile.avatarUrl!, client)
      : null;

  @override
  Color get defaultColor => MatrixMember.hashColor(profile.userId);

  @override
  String? get detail => profile.userId;

  @override
  String get displayName => profile.displayName ?? profile.userId;

  @override
  String get identifier => profile.userId;

  @override
  String get userName => profile.userId;

  MatrixProfile(this.client, this.profile);
}
