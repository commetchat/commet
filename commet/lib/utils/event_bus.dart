import 'dart:async';
import 'package:commet/client/components/message_effects/message_effect_particles.dart';
import 'package:commet/client/room.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class EventBus {
  /// First string is room id, Second string is client id
  static StreamController<(String, String?)> openRoom =
      StreamController<(String, String?)>.broadcast();

  /// 0] Client Id
  /// 1] Room Id
  /// 2] Thread Root Event Id
  static StreamController<(String, String, String)> openThread =
      StreamController<(String, String, String)>.broadcast();

  static StreamController<void> closeThread = StreamController.broadcast();

  /// Called when the user initially logs in to the app, or on app startup when atleast one user account is already logged in
  static StreamController<BuildContext> onLoggedIn =
      StreamController<BuildContext>.broadcast();

  static StreamController<DropDoneDetails> onFileDropped =
      StreamController<DropDoneDetails>.broadcast();

  static StreamController<Room?> onSelectedRoomChanged =
      StreamController<Room?>.broadcast();

  static StreamController<void> startSearch = StreamController.broadcast();

  static StreamController<void> openPinnedMessages =
      StreamController.broadcast();

  static StreamController<String> jumpToEvent = StreamController.broadcast();

  static StreamController<void> focusTimeline = StreamController.broadcast();

  static StreamController<MessageEffectParticles> doMessageEffect =
      StreamController.broadcast();
}
