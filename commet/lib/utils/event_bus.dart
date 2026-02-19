import 'dart:async';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/message_effects/message_effect_particles.dart';
import 'package:commet/ui/molecules/overlapping_panels.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class EventBus {
  /// First string is room id, Second string is client id
  static StreamController<(String, String?)> openRoom =
      StreamController<(String, String?)>.broadcast();

  /// First string is user id, Second string is client id, third string is context room
  static StreamController<(String, String, String?)> openUserProfile =
      StreamController<(String, String, String?)>.broadcast();

  /// 0] Client Id
  /// 1] Room Id
  /// 2] Thread Root Event Id
  static StreamController<(String, String, String)> openThread =
      StreamController<(String, String, String)>.broadcast();

  static StreamController<void> closeThread = StreamController.broadcast();

  static StreamController<Client?> setFilterClient =
      StreamController.broadcast();

  /// Called when the user initially logs in to the app, or on app startup when atleast one user account is already logged in
  static StreamController<BuildContext> onLoggedIn =
      StreamController<BuildContext>.broadcast();

  static StreamController<DropDoneDetails> onFileDropped =
      StreamController<DropDoneDetails>.broadcast();

  static StreamController<Space?> onSelectedSpaceChanged =
      StreamController<Space?>.broadcast();

  static StreamController<Room?> onSelectedRoomChanged =
      StreamController<Room?>.broadcast();

  static StreamController<void> startSearch = StreamController.broadcast();

  static StreamController<void> openPinnedMessages =
      StreamController.broadcast();

  static StreamController<void> openCalendar = StreamController.broadcast();

  static StreamController<void> toggleRoomSidePanel =
      StreamController.broadcast();

  static StreamController<String> jumpToEvent = StreamController.broadcast();

  static StreamController<void> focusTimeline = StreamController.broadcast();

  static StreamController<MessageEffectParticles> doMessageEffect =
      StreamController.broadcast();

  static StreamController<ScopePopped> onPopInvoked =
      StreamController.broadcast(sync: true);
}

class ScopePopped {
  RevealSide? currentMobileSide;
  bool handled = false;
}
