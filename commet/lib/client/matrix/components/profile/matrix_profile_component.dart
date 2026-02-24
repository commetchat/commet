import 'dart:convert';
import 'dart:typed_data';

import 'package:canonical_json/canonical_json.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/components/user_color/user_color_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';

import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/client/matrix/matrix_member.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/atoms/rich_text/matrix_html_parser.dart';
import 'package:commet/utils/color_utils.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/matrix_api_lite/matrix_api.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

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
        ProfileWithBadges,
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
  ImageProvider? get banner {
    try {
      if (fields.containsKey(MatrixProfileComponent.bannerKey)) {
        var url = fields[MatrixProfileComponent.bannerKey];

        if (url is String) {
          // There is an issue where some homeservers are returning extra quotes here
          if (url.startsWith("\"") && url.endsWith("\"")) {
            url = url.substring(1, url.length - 1);
          }

          return MatrixMxcImage(
              Uri.parse(fields[MatrixProfileComponent.bannerKey]),
              doFullres: true,
              doThumbnail: false,
              autoLoadFullRes: true,
              client.matrixClient);
        }
      }
    } catch (e, s) {
      Log.onError(e, s, content: "Error while getting profile banner");
    }

    return null;
  }

  @override
  Color get defaultColor =>
      client.getComponent<UserColorComponent>()?.getColor(profile.userId) ??
      MatrixMember.hashColor(profile.userId);

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

  @override
  Future<List<ProfileBadge>> getBadges() async {
    try {
      List<dynamic>? content = fields[MatrixProfileComponent.badgeKey];
      if (content == null) return [];

      List<ProfileBadge> badges = List.empty(growable: true);

      for (var entry in content) {
        var badge = await badgeFromContent(client, identifier, entry);
        if (badge != null) {
          badges.add(badge);
        }
      }

      return badges;
    } catch (e, s) {
      Log.onError(e, s);
      return [];
    }
  }

  static Future<ProfileBadge?> badgeFromContent(MatrixClient client,
      String recipientIdentifier, Map<String, dynamic> entry) async {
    var isValid = await validateBadgeSignature(entry);
    if (!isValid) return null;

    var signedContent = entry["signed"];
    if (!validateAwardRecipient(recipientIdentifier, signedContent)) {
      return null;
    }

    var awardContent = signedContent["content"] as Map<String, dynamic>?;
    if (awardContent == null) return null;

    var image = awardContent["image"];
    var body = awardContent["body"];
    var brightnessStr = awardContent["chat.commet.image_brightness"];

    Brightness? brightness;
    if (brightnessStr == "light") {
      brightness = Brightness.light;
    }

    if (brightnessStr == "dark") {
      brightness = Brightness.dark;
    }

    var linkStr = signedContent["href"] as String?;

    Uri? link;
    if (linkStr != null) {
      link = Uri.parse(linkStr);
      if (link.scheme != "https") {
        link = null;
      }
    }

    return ProfileBadge(
        MatrixMxcImage(
          Uri.parse(image),
          client.matrixClient,
          doFullres: true,
          doThumbnail: false,
          autoLoadFullRes: true,
        ),
        source: entry,
        sender: signedContent["sender"],
        id: signedContent["id"],
        body: body,
        link: link,
        brightness: brightness);
  }

  static bool validateAwardRecipient(
      String recipientIdentifier, Map<String, dynamic> awardContent) {
    if (awardContent.containsKey("user_id_hash")) {
      var hashBytes = Uint8List.fromList(
          sha256.convert(AsciiEncoder().convert(recipientIdentifier)).bytes);

      var expectedHash = TextUtils.toHexString(hashBytes);

      if (awardContent["user_id_hash"] != expectedHash) {
        Log.i(
            "This award has a has which does not match the current user, Expected: $expectedHash, but got: ${awardContent["user_id_hash"]}");

        return false;
      } else {
        Log.i("Award hash valid!");
        return true;
      }
    } else if (awardContent.containsKey("user_id")) {
      if (awardContent["user_id"] != recipientIdentifier) {
        Log.i(
            "Expected user $recipientIdentifier but got ${awardContent["user_id"]}");
        return false;
      }

      return true;
    } else {
      Log.i("No way to validate who this badge was intended for, skipping");
      return false;
    }
  }

  static Future<bool> validateBadgeSignature(Map<String, dynamic> entry) async {
    const knownPublicKeys = {
      "@awards:data.commet.chat": {
        "8d4f773c": "a3KSUrUaC0nph7EpOpC1Y6XDnYHttUW5jns3euZ8D+E"
      }
    };

    Log.i("Verifying signature content");

    var signed = entry["signed"];
    var signatures = entry["signatures"] as Map<String, dynamic>;

    var canonical = canonicalJson.encode(signed);
    var canonicalString = String.fromCharCodes(canonical);

    var keys = knownPublicKeys[signed["sender"]];

    if (keys == null) {
      Log.e(
          "Could not find any known public key for sender: ${signed["sender"]}");
      return false;
    }

    Log.i(
      "Known keys for sender: ${signed["sender"]}: $keys",
    );

    for (var entry in signatures.entries) {
      var publicKeyB64 = keys[entry.key];

      if (publicKeyB64 != null) {
        Log.i("Verifying with public key: $publicKeyB64");
        var publicKey = vod.Ed25519PublicKey.fromBase64(publicKeyB64);
        var signature = vod.Ed25519Signature.fromBase64(entry.value);

        try {
          publicKey.verify(message: canonicalString, signature: signature);
          Log.i("Successfully verified!");
          return true;
        } catch (_) {
          Log.i("Verification Failed for this signature");
        }
      }
    }

    return false;
  }
}

class MatrixProfileComponent implements UserProfileComponent<MatrixClient> {
  static const String bannerKey = "chat.commet.profile_banner";
  static const String colorSchemeKey = "chat.commet.profile_color_scheme";
  static const String bioKey = "chat.commet.profile_bio";
  static const String badgeKey = "chat.commet.profile_badges";
  static const String statusKey = "chat.commet.profile_status";
  static const String pronounsKey = "io.fsky.nyx.pronouns";

  @override
  MatrixClient client;

  MatrixProfileComponent(this.client);

  @override
  Future<Profile> getProfile(String identifier) async {
    try {
      var fields = await client.matrixClient.request(RequestType.GET,
          "/client/v3/profile/${Uri.encodeComponent(identifier)}");
      fields["user_id"] = identifier;

      var precense = await client
          .getComponent<UserPresenceComponent>()
          ?.getUserPresence(identifier);

      if (precense == null || precense.message == null) {
        if (fields.containsKey(statusKey)) {
          precense = UserPresence(UserPresenceStatus.unknown,
              message: UserPresenceMessage(fields[statusKey].toString(),
                  PresenceMessageType.userCustom));
        }
      }

      return MatrixProfile(client, matrix.Profile.fromJson(fields),
          precence: precense, fields: fields);
    } catch (e, s) {
      Log.onError(e, s, content: "Error while fetching profile");
      return MatrixProfile(client, matrix.Profile(userId: identifier));
    }
  }

  @override
  Future<void> setBanner(Uint8List bytes) async {
    var mxc = await client.matrixClient.uploadContent(bytes);

    await setField(bannerKey, mxc.toString());
  }

  Future<void> setField(String field, dynamic content) async {
    final data = {field: content};

    var response = await client.matrixClient.request(RequestType.PUT,
        "/client/v3/profile/${Uri.encodeComponent(client.self!.identifier)}/$field",
        data: data);

    print(response);
  }

  Future<void> removeField(String field) async {
    var response = await client.matrixClient.request(
      RequestType.DELETE,
      "/client/v3/profile/${Uri.encodeComponent(client.self!.identifier)}/$field",
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
  Future<void> setStatus(String? status) {
    if (status == null) {
      return removeField(statusKey);
    } else {
      return setField(statusKey, status);
    }
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

  @override
  Future<List<ProfileBadge>> getAvailableBadges() async {
    var accountEntries = client.matrixClient.accountData.entries
        .where((i) => i.key.startsWith("chat.commet.profile_badge."));

    List<ProfileBadge> badges = List.empty(growable: true);
    for (var entry in accountEntries) {
      var award = await MatrixProfile.badgeFromContent(
          client, client.self!.identifier, entry.value.content);
      if (award != null) {
        badges.add(award);
      }
    }

    return badges;
  }

  @override
  Future<void> setProfileBadges(List<ProfileBadge> badges) {
    return setField(
        "chat.commet.profile_badges", badges.map((i) => i.source).toList());
  }
}
