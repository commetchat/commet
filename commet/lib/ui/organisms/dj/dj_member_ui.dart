// The booth as it shows on call members, wherever they are listed (the
// sidebar's voice list, the call tiles): a spinning record next to the DJ, a
// raised hand next to whoever asked for the decks, and the right-click
// actions to ask for, pass or leave the decks.
import 'package:commet/client/components/dj/dj_session.dart';
import 'package:commet/ui/organisms/dj/vinyl_disc.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

const djHandEmoji = '✋';

class DjMemberBadges extends StatelessWidget {
  const DjMemberBadges(
      {required this.dj, required this.userId, this.size = 16, super.key});

  final DjSession? dj;
  final String userId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dj = this.dj;
    if (dj == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: dj,
      builder: (context, _) {
        final isDj = dj.isDjUser(userId);
        final asked = !isDj && dj.hasRequestedUser(userId);
        if (!isDj && !asked) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (isDj)
              Tooltip(
                message: dj.current == null
                    ? 'DJ'
                    : 'DJ · ${dj.isPlaying ? 'playing' : 'paused'} '
                        '${dj.current!.title}',
                child: VinylDisc(
                  size: size,
                  spinning: dj.isPlaying && !dj.isBuffering,
                ),
              ),
            if (asked)
              Tooltip(
                message: 'Asked to be the DJ',
                child: Text(djHandEmoji,
                    style: TextStyle(fontSize: size * 0.85, height: 1)),
              ),
          ],
        );
      },
    );
  }
}

/// Right-click actions on the call member [userId] ([displayName]).
///
/// On the DJ, [musicVolume] (the listener's own music slider) comes first:
/// right-clicking whoever plays the music is where people look for it.
List<tiamat.ContextMenuItem> djMemberMenuItems(
  DjSession? dj, {
  required String userId,
  required String displayName,
  Widget? musicVolume,
}) {
  if (dj == null || dj.isDisposed) return const [];
  final actions = _actions(dj, userId: userId, displayName: displayName);
  if (musicVolume == null || !dj.isDjUser(userId) || dj.current == null) {
    return actions;
  }
  return [
    tiamat.ContextMenuItem(
      text: 'Music volume',
      customBuilder: (context, onClicked, {closeMenu}) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            const tiamat.Text.labelLow('Music'),
            musicVolume,
          ],
        ),
      ),
    ),
    ...actions,
  ];
}

List<tiamat.ContextMenuItem> _actions(
  DjSession dj, {
  required String userId,
  required String displayName,
}) {
  final isSelf = userId == dj.selfUserId;
  final canDj = dj.caps.canDj;

  if (dj.isDj) {
    if (isSelf) {
      return [
        tiamat.ContextMenuItem(
            text: 'Stop DJing',
            icon: Icons.album_outlined,
            onPressed: () => dj.stopDjing()),
      ];
    }
    final candidate = dj.passCandidateFor(userId);
    if (candidate != null && dj.passTarget == candidate) {
      return [
        tiamat.ContextMenuItem(
            text: 'Stop handing over to $displayName',
            icon: Icons.close_rounded,
            onPressed: dj.cancelPass),
      ];
    }
    if (candidate != null) {
      return [
        tiamat.ContextMenuItem(
            text: dj.hasRequestedUser(userId)
                ? 'Pass the decks to $displayName $djHandEmoji'
                : 'Pass the decks to $displayName',
            icon: Icons.album_rounded,
            onPressed: () => dj.passTo(candidate)),
      ];
    }
    final platform = dj.platformOf(userId);
    return [
      _note(platform == null
          ? "$displayName's app can't DJ"
          : "$displayName is on ${_platformName(platform)}: only the "
              'desktop app can DJ'),
    ];
  }

  if (dj.isDjUser(userId) && !isSelf) {
    if (!canDj) return [_note('DJing needs the desktop app (Windows or Linux)')];
    if (dj.isJoining) return const [];
    return [
      dj.hasRequested
          ? tiamat.ContextMenuItem(
              text: 'Stop asking to be the DJ',
              icon: Icons.back_hand_outlined,
              onPressed: () => dj.requestDj(false))
          : tiamat.ContextMenuItem(
              text: 'Request to become DJ',
              icon: Icons.back_hand_rounded,
              onPressed: () => dj.requestDj(true)),
    ];
  }

  if (isSelf && dj.isVacant && dj.role == DjRole.listener) {
    if (!canDj) return [_note('DJing needs the desktop app (Windows or Linux)')];
    return [
      tiamat.ContextMenuItem(
          text: 'Become the DJ',
          icon: Icons.album_rounded,
          onPressed: () => dj.becomeDj()),
    ];
  }

  return const [];
}

String _platformName(String platform) => switch (platform) {
      'web' => 'the web',
      'android' => 'Android',
      'ios' => 'iOS',
      'macos' => 'macOS',
      _ => platform,
    };

/// A menu line that explains instead of acting.
tiamat.ContextMenuItem _note(String text) => tiamat.ContextMenuItem(
      text: text,
      customBuilder: (context, onClicked, {closeMenu}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: Theme.of(context).colorScheme.outline),
              Flexible(child: tiamat.Text.labelLow(text)),
            ],
          ),
        ),
      ),
    );
