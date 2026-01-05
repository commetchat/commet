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

abstract class UserProfileComponent<T extends Client> implements Component<T> {
  /// Gets a peer by ID. will return a peer object for any given ID and then load the data from the server.
  /// This is so that you can display any given peer without having to load the data for it
  Future<Profile?> getProfile(String identifier);

  Future<void> setBanner(Uint8List bytes);

  Future<void> setProfileColorScheme(Color color, Brightness brightness);
}
