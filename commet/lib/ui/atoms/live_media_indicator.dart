import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/ui/atoms/tiny_pill.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// What a voice channel member publishes, shown after their name in the room
/// list (issue #9): a red LIVE pill while they share their screen, or a
/// camera icon while only their camera is on.
class LiveMediaIndicator extends StatelessWidget {
  const LiveMediaIndicator(this.media, {super.key});

  final Set<LiveMedia> media;

  String get labelLiveBadge => Intl.message("LIVE",
      name: "labelLiveBadge",
      desc: "Badge next to a voice channel member who is sharing their screen");

  String get tooltipLiveScreenShare => Intl.message("Sharing their screen",
      name: "tooltipLiveScreenShare",
      desc: "Tooltip of the LIVE badge next to a voice channel member");

  String get tooltipLiveCamera => Intl.message("Camera on",
      name: "tooltipLiveCamera",
      desc: "Tooltip of the camera icon next to a voice channel member");

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.of(context);

    if (media.contains(LiveMedia.screen)) {
      return Tooltip(
        message: tooltipLiveScreenShare,
        child: TinyPill(labelLiveBadge,
            background: colors.error, foreground: colors.onError),
      );
    }

    if (media.contains(LiveMedia.camera)) {
      return Tooltip(
        message: tooltipLiveCamera,
        child: Icon(Icons.videocam_rounded,
            size: 16, color: colors.onSurfaceVariant),
      );
    }

    return const SizedBox.shrink();
  }
}
