import 'dart:convert';
import 'dart:typed_data';

import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';

import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/client/matrix/matrix_member.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/ui/atoms/rich_text/matrix_html_parser.dart';
import 'package:commet/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/matrix_api_lite/matrix_api.dart';

// ignore: implementation_imports
import 'package:matrix/src/utils/markdown.dart' as mx_markdown;

class MatrixProfile
    implements
        Profile,
        ProfileWithBanner,
        ProfileWithPresence,
        ProfileWithColorScheme,
        ProfileWithPronouns,
        ProfileWithTimezone,
        ProfileWithBio {
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

  @override
  List<String> get pronouns {
    var array = fields[MatrixProfileComponent.pronounsKey];

    try {
      if (array is List<dynamic>) {
        return array.map((i) => i["summary"].toString()).toList();
      }
    } catch (_) {}

    return [];
  }

  @override
  String get source => JsonEncoder.withIndent("  ").convert(fields);

  @override
  String? get timezone => fields["m.tz"] as String?;

  @override
  Widget buildBio(BuildContext context, ThemeData theme,
      {String? overrideText}) {
    Map<String, dynamic>? content = fields[MatrixProfileComponent.bioKey];

    if (overrideText != null) {
      content = MatrixProfileComponent.textToContent(overrideText, client);
    }

    if (content == null) return Container();

    if (content["format"] == "org.matrix.custom.html") {
      return Material(
        color: Colors.transparent,
        child: MatrixHtmlParser.parse(content["formatted_body"], client, null),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Text(
        content["body"],
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurface),
      ),
    );
  }

  @override
  bool get hasBio => fields.containsKey(MatrixProfileComponent.bioKey);

  @override
  String? get plaintextBio => fields[MatrixProfileComponent.bioKey]?["body"];
}

class MatrixProfileComponent implements UserProfileComponent<MatrixClient> {
  static const String bannerKey = "chat.commet.profile_banner";
  static const String colorSchemeKey = "chat.commet.profile_color_scheme";
  static const String bioKey = "chat.commet.profile_bio";
  static const String statusKey = "chat.commet.profile_status";
  static const String pronounsKey = "io.fsky.nyx.pronouns";

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

  Future<void> removeField(String field) async {
    var response = await client.matrixClient.request(
      RequestType.DELETE,
      "/client/v3/profile/${client.self!.identifier}/$field",
    );

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

  @override
  Future<void> setTimezone(String timezone) {
    return setField("m.tz", timezone);
  }

  @override
  Future<void> removeTimezone() {
    return removeField("m.tz");
  }

  @override
  Future<void> setBio(String bio) async {
    Map<String, String> content = textToContent(bio, client);

    await setField(bioKey, content);
  }

  static Map<String, String> textToContent(String bio, MatrixClient client) {
    var emoticons = client.getComponent<MatrixEmoticonComponent>();
    final html = mx_markdown.markdown(
      bio,
      getEmotePacks: emoticons != null
          ? () => emoticons.getEmotePacksFlat(matrix.ImagePackUsage.emoticon)
          : null,
    );

    var content = {
      "body": bio,
    };

    if (HtmlUnescape().convert(html.replaceAll(RegExp(r'<br />\n?'), '\n')) !=
        bio) {
      content["format"] = "org.matrix.custom.html";
      content["formatted_body"] = html;
    }
    return content;
  }

  @override
  Future<void> removeBio() {
    return removeField(bioKey);
  }
}
