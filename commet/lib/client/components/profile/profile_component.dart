import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:flutter/material.dart';

abstract class Profile {
  String get identifier;
  String get userName;
  String get displayName;
  String? get detail;
  ImageProvider? get avatar;
  ImageProvider? get banner;
  Color get defaultColor;

  String get source;
}

abstract class ProfileWithPresence {
  UserPresence? precence;
}

abstract class ProfileWithBanner {
  UserPresence? precence;
}

abstract class ProfileWithColorScheme {
  Color? get color;
  Brightness? get brightness;
}

abstract class ProfileWithPronouns {
  List<String> get pronouns;
}

abstract class ProfileWithBadges {
  Future<List<ProfileBadge>> getBadges();
}

class ProfileBadge {
  ImageProvider image;
  String body;
  Brightness? brightness;
  String id;
  String sender;
  Uri? link;
  Map<String, dynamic> source;

  ProfileBadge(this.image,
      {required this.body,
      required this.id,
      required this.sender,
      required this.source,
      this.brightness,
      this.link});

  @override
  bool operator ==(Object other) {
    if (other is! ProfileBadge) return false;

    return other.body == body &&
        other.id == id &&
        other.sender == sender &&
        other.brightness == brightness;
  }

  @override
  int get hashCode => id.hashCode;
}

abstract class ProfileWithTimezone {
  String? get timezone;
}

abstract class ProfileWithBio {
  bool get hasBio;

  String? get plaintextBio;

  Widget buildBio(BuildContext context, ThemeData theme,
      {String? overrideText});
}

abstract class UserProfileComponent<T extends Client> implements Component<T> {
  /// Gets a peer by ID. will return a peer object for any given ID and then load the data from the server.
  /// This is so that you can display any given peer without having to load the data for it
  Future<Profile> getProfile(String identifier);

  Future<void> setBanner(Uint8List bytes);

  Future<void> setProfileColorScheme(Color color, Brightness brightness);

  Future<void> setStatus(String? status);

  Future<void> setTimezone(String timezone);

  Future<void> setBio(String bio);

  Future<void> removeBio();

  Future<void> removeTimezone();

  Future<List<ProfileBadge>> getAvailableBadges();

  Future<void> setProfileBadges(List<ProfileBadge> badges);
}
