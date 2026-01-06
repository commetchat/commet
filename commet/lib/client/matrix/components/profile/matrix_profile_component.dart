import 'dart:typed_data';

import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';

import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/client/matrix/matrix_member.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/utils/color_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/matrix_api_lite/matrix_api.dart';

class MatrixProfile
    implements
        Profile,
        ProfileWithBanner,
        ProfileWithPresence,
        ProfileWithColorScheme {
  matrix.Profile profile;
  MatrixClient client;

  Map<String, dynamic> fields;

  @override
  ImageProvider<Object>? get avatar => profile.avatarUrl != null
      ? MatrixMxcImage(profile.avatarUrl!, client.matrixClient,
          autoLoadFullRes: false, thumbnailHeight: 128, fullResHeight: 128)
      : null;

  @override
  ImageProvider? get banner =>
      fields.containsKey(MatrixProfileComponent.bannerKey)
          ? MatrixMxcImage(
              Uri.parse(fields[MatrixProfileComponent.bannerKey]),
              doFullres: true,
              doThumbnail: false,
              autoLoadFullRes: true,
              client.matrixClient)
          : null;

  @override
  Color get defaultColor => MatrixMember.hashColor(profile.userId);

  @override
  String? get detail => profile.userId;

  @override
  String get displayName =>
      fields["displayname"] ?? profile.displayName ?? profile.userId;

  @override
  String get identifier => profile.userId;

  @override
  String get userName => profile.userId;

  MatrixProfile(this.client, this.profile,
      {this.precence, this.fields = const {}});

  @override
  UserPresence? precence;

  @override
  Brightness? get brightness =>
      fields.containsKey(MatrixProfileComponent.colorSchemeKey) == false
          ? null
          : switch (fields[MatrixProfileComponent.colorSchemeKey]
              ["brightness"]) {
              "light" => Brightness.light,
              "dark" => Brightness.dark,
              _ => null,
            };

  @override
  Color? get color {
    if (fields.containsKey(MatrixProfileComponent.colorSchemeKey) == false) {
      return null;
    }

    var hexString =
        fields[MatrixProfileComponent.colorSchemeKey]["color"] as String?;
    if (hexString == null) return null;

    return ColorUtils.fromHexCode(hexString);
  }
}

class MatrixProfileComponent implements UserProfileComponent<MatrixClient> {
  static const String bannerKey = "chat.commet.profile_banner";
  static const String colorSchemeKey = "chat.commet.profile_color_scheme";
  static const String statusKey = "chat.commet.profile_status";

  @override
  MatrixClient client;

  MatrixProfileComponent(this.client);

  @override
  Future<Profile?> getProfile(String identifier) async {
    var fields = await client.matrixClient
        .request(RequestType.GET, "/client/v3/profile/${identifier}");
    fields["user_id"] = identifier;

    var precense = await client
        .getComponent<UserPresenceComponent>()
        ?.getUserPresence(identifier);

    if (precense == null || precense.message == null) {
      if (fields.containsKey(statusKey)) {
        precense = UserPresence(UserPresenceStatus.unknown,
            message: UserPresenceMessage(
                fields[statusKey].toString(), PresenceMessageType.userCustom));
      }
    }

    return MatrixProfile(client, matrix.Profile.fromJson(fields),
        precence: precense, fields: fields);
  }

  @override
  Future<void> setBanner(Uint8List bytes) async {
    var mxc = await client.matrixClient.uploadContent(bytes);

    await setField(bannerKey, mxc.toString());
  }

  Future<void> setField(String field, dynamic content) async {
    final data = {field: content};

    var response = await client.matrixClient.request(
        RequestType.PUT, "/client/v3/profile/${client.self!.identifier}/$field",
        data: data);

    print(response);
  }

  @override
  Future<void> setProfileColorScheme(Color color, Brightness brightness) async {
    await setField(colorSchemeKey, {
      "color": color.toHexCode(),
      "brightness": switch (brightness) {
        Brightness.dark => "dark",
        Brightness.light => "light",
      }
    });
  }

  @override
  Future<void> setStatus(String status) {
    return setField(statusKey, status);
  }
}
