import 'package:commet/utils/pronoun_utils.dart';

class MatrixPerMessageProfileData {
  static const String stableKey = "m.per_message_profile";
  static const String unstableKey = "com.beeper.per_message_profile";

  final String id;
  final String? displayName;
  final String? avatarUrl;
  final bool clearAvatar;
  final bool hasFallback;
  final List<String> pronouns;

  const MatrixPerMessageProfileData(
      {required this.id,
      this.displayName,
      this.avatarUrl,
      this.clearAvatar = false,
      this.hasFallback = false,
      this.pronouns = const []});

  static MatrixPerMessageProfileData? fromEventContent(
      Map<String, Object?> content) {
    var profile = content[stableKey] ?? content[unstableKey];

    if (profile is! Map) {
      return null;
    }

    var displayName = profile["displayname"];
    if (displayName is! String || displayName.trim().isEmpty) {
      displayName = null;
    }

    String? avatarUrl;
    bool clearAvatar = false;
    var url = profile["avatar_url"];

    if (url is String && url.isNotEmpty) {
      avatarUrl = url;
    } else if (url is String) {
      clearAvatar = true;
    } else if (profile["avatar_file"] != null) {
      // Encrypted avatars are not supported so just treat is as if they cleared it
      clearAvatar = true;
    }

    var id = profile["id"];

    if (id is! String &&
        displayName == null &&
        avatarUrl == null &&
        !clearAvatar) {
      return null;
    }

    return MatrixPerMessageProfileData(
        id: id is String ? id : "",
        displayName: displayName as String?,
        avatarUrl: avatarUrl,
        clearAvatar: clearAvatar,
        hasFallback: profile["has_fallback"] == true,
        pronouns: parsePronounsField(profile[pronounsFieldKey]));
  }
}

String stripPerMessageProfileFallback(String body, String displayName) {
  var prefix = "$displayName: ";
  return body.startsWith(prefix) ? body.substring(prefix.length) : body;
}

final RegExp _htmlFallback = RegExp(
    r'^(\s*<mx-reply>.*?</mx-reply>)?\s*<strong[^>]*data-mx-profile-fallback[^>]*>.*?</strong>',
    caseSensitive: false,
    dotAll: true);

String stripPerMessageProfileFallbackHtml(String html) =>
    html.replaceFirstMapped(_htmlFallback, (match) => match.group(1) ?? "");
