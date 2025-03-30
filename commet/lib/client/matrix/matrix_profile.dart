import 'package:commet/client/matrix/matrix_member.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/profile.dart';
import 'package:commet/ui/pages/developer/app_inspector/value_reflector_widget.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart' as matrix;

@Reflector()
class MatrixProfile implements Profile {
  matrix.Profile profile;
  matrix.Client client;

  @override
  ImageProvider<Object>? get avatar => profile.avatarUrl != null
      ? MatrixMxcImage(profile.avatarUrl!, client,
          autoLoadFullRes: false, thumbnailHeight: 128, fullResHeight: 128)
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
