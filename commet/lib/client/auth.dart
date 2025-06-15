import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';

abstract class LoginFlow {
  Future<LoginResult> submit(Client client);
}

abstract class PasswordLoginFlow implements LoginFlow {
  String? username;
  String? password;
}

abstract class SsoLoginFlow implements LoginFlow {
  ImageProvider? icon;
  String get name;
  String? get id;
}
