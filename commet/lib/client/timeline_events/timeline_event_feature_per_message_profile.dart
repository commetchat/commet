import 'package:commet/client/timeline.dart';
import 'package:flutter/material.dart';

class PerMessageProfile {
  final String id;
  final String? displayName;
  final ImageProvider? avatar;
  final bool clearAvatar;
  final bool hasFallback;
  final List<String> pronouns;
  final Color color;

  const PerMessageProfile(
      {required this.id,
      required this.color,
      this.displayName,
      this.avatar,
      this.clearAvatar = false,
      this.hasFallback = false,
      this.pronouns = const []});

  bool get hasDisplayName => displayName != null;
}

abstract class TimelineEventFeaturePerMessageProfile {
  PerMessageProfile? getPerMessageProfile({Timeline? timeline});
}
