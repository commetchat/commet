// The DJ booth: who's on the decks, what's playing, what's next.
//
// Everyone sees the same booth; only the DJ's has controls. Listeners get
// their own volume and, on desktop, a way to ask for the decks.
import 'dart:async';

import 'package:commet/client/components/dj/dj_links.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/components/dj/dj_session.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_stream.dart';
import 'package:commet/client/member.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/dj/dj_member_ui.dart';
import 'package:commet/ui/organisms/dj/vinyl_disc.dart';
import 'package:commet/utils/links/link_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

/// "3:07", "1:02:45".
String formatDjTime(int ms) {
  final total = (ms / 1000).floor();
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = (total % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

double get maxDjMusicVolume => kIsWeb ? 1.0 : 1.5;

/// Sets how loud the booth's music plays for us. [save] keeps it: while a
/// slider is dragged only the sound follows, and the level is saved (with
/// everything listening to settings) once, when it is let go.
Future<void> setDjMusicVolume(VoipSession session, double volume,
    {bool save = true}) async {
  final streams = session.streams
      .where((s) =>
          s.type == VoipStreamType.music &&
          s.direction == VoipStreamDirection.incoming)
      .toList();
  if (!save) {
    for (final stream in streams.whereType<MatrixLivekitVoipStream>()) {
      if (!session.isDeafened) stream.applyVolume(volume);
    }
    _liveMusicVolume.value = volume;
    return;
  }
  _liveMusicVolume.value = null;
  if (streams.isEmpty) {
    await preferences.djMusicVolume.set(volume);
    return;
  }
  for (final stream in streams) {
    await stream.setVolume(volume);
  }
}

/// The level while a music slider is being dragged, for the DJ's monitor
/// and the other sliders; null otherwise.
final ValueNotifier<double?> _liveMusicVolume = ValueNotifier(null);
ValueListenable<double?> get liveDjMusicVolume => _liveMusicVolume;

class DjBoothPanel extends StatelessWidget {
  const DjBoothPanel(
      {required this.session, required this.dj, this.onClose, super.key});

  final VoipSession session;
  final DjSession dj;
  final VoidCallback? onClose;

  Member _member(String userId) =>
      session.client.getRoom(session.roomId)!.getMemberOrFallback(userId);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: tiamat.Tile.low(
        child: ListenableBuilder(
          listenable: dj,
          builder: (context, _) {
            if (dj.isDisposed) return const SizedBox.shrink();
            final nobody = dj.djIdentity == null || dj.isVacant;
            final vacant = nobody && !dj.isJoining && !dj.isDj;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context),
                Expanded(
                  child: vacant
                      ? _Vacant(dj: dj)
                      : _Booth(session: session, dj: dj, memberOf: _member),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 6),
      child: Row(
        children: [
          VinylDisc(size: 20, spinning: dj.isPlaying && !dj.isBuffering),
          const SizedBox(width: 10),
          const Expanded(child: tiamat.Text.largeTitle('DJ Booth')),
          if (onClose != null)
            IconButton(
              tooltip: 'Close the booth',
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}

class _Vacant extends StatelessWidget {
  const _Vacant({required this.dj});

  final DjSession dj;

  @override
  Widget build(BuildContext context) {
    final leftover = dj.current != null || dj.queue.isNotEmpty;
    final count = dj.queue.length + (dj.current != null ? 1 : 0);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            const VinylDisc(size: 120, spinning: false),
            const SizedBox(height: 4),
            const tiamat.Text.largeTitle('The decks are free'),
            tiamat.Text.labelLow(
              leftover
                  ? 'Pick up where the last DJ left off: $count '
                      '${count == 1 ? 'song' : 'songs'} waiting.'
                  : 'Play music everyone in the call hears at the same time. '
                      'Each listener sets their own volume.',
            ),
            const SizedBox(height: 4),
            if (dj.caps.canDj)
              tiamat.Button(text: 'Become the DJ', onTap: () => dj.becomeDj())
            else
              const DjDesktopOnlyNote(),
          ],
        ),
      ),
    );
  }
}

class DjDesktopOnlyNote extends StatelessWidget {
  const DjDesktopOnlyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Icon(Icons.desktop_windows_outlined, size: 20),
            Flexible(
              child: tiamat.Text.labelLow(
                  'DJing needs the desktop app (Windows or Linux). '
                  'You can listen from here.'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A booth with a DJ: everything in one scroll, so no section can push
/// another off screen however many requests or links pile up.
class _Booth extends StatelessWidget {
  const _Booth(
      {required this.session, required this.dj, required this.memberOf});

  final VoipSession session;
  final DjSession dj;
  final Member Function(String userId) memberOf;

  /// Editing is the DJ's, and stops while the decks change hands.
  bool get editable => dj.isDj && dj.passTarget == null;

  @override
  Widget build(BuildContext context) {
    final queue = dj.queue;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _DjStrip(key: const ValueKey('strip'), dj: dj, memberOf: memberOf),
        ),
        if (_handover(context) case final line?)
          SliverToBoxAdapter(key: const ValueKey('handover'), child: line),
        SliverToBoxAdapter(
          key: const ValueKey('now'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: _NowPlaying(session: session, dj: dj),
          ),
        ),
        if (dj.isDj)
          SliverToBoxAdapter(
            key: const ValueKey('add'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _AddBar(dj: dj, enabled: editable),
            ),
          ),
        if (dj.isDj && dj.requests.isNotEmpty)
          SliverToBoxAdapter(
            key: const ValueKey('requests'),
            child: _Requests(dj: dj, memberOf: memberOf),
          ),
        SliverToBoxAdapter(
          key: const ValueKey('queue-header'),
          child: _QueueHeader(dj: dj, editable: editable),
        ),
        if (queue.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: tiamat.Text.labelLow(dj.isDj
                  ? 'Songs you add line up here. Drag them to reorder.'
                  : 'Nothing queued.'),
            ),
          )
        else if (editable)
          SliverReorderableList(
            itemCount: queue.length,
            onReorder: dj.move,
            itemBuilder: (context, i) => _QueueRow(
              key: ValueKey(queue[i].id),
              dj: dj,
              track: queue[i],
              index: i,
              editable: true,
              addedBy: memberOf(queue[i].addedBy),
            ),
          )
        else
          SliverList.builder(
            itemCount: queue.length,
            itemBuilder: (context, i) => _QueueRow(
              key: ValueKey(queue[i].id),
              dj: dj,
              track: queue[i],
              index: i,
              editable: false,
              addedBy: memberOf(queue[i].addedBy),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
      ],
    );
  }

  Widget? _handover(BuildContext context) {
    final target = dj.passTarget;
    if (target == null || dj.isJoining) return null;
    final member = memberOf(djUserIdOf(target));
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          child: Row(
            spacing: 10,
            children: [
              const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              Expanded(
                child: tiamat.Text.labelLow(dj.isDj
                    ? 'Handing the decks to ${member.displayName}. The music '
                        'keeps playing; the queue is locked until they take '
                        'over.'
                    : 'Handing the decks to ${member.displayName}…'),
              ),
              if (dj.isDj)
                TextButton(
                    onPressed: dj.cancelPass, child: const Text('Cancel')),
            ],
          ),
        ),
      ),
    );
  }
}

class _DjStrip extends StatelessWidget {
  const _DjStrip({required this.dj, required this.memberOf, super.key});

  final DjSession dj;
  final Member Function(String userId) memberOf;

  @override
  Widget build(BuildContext context) {
    final member = memberOf(dj.djUserId ?? dj.selfUserId);
    final you = dj.isDj || dj.djIdentity == dj.selfIdentity;
    final String line;
    if (dj.isJoining && dj.djIdentity != dj.selfIdentity) {
      line = '${member.displayName} is handing you the decks…';
    } else if (dj.isJoining) {
      line = 'Getting the decks ready…';
    } else {
      line = you
          ? "You're on the decks"
          : '${member.displayName} is on the decks';
    }

    Widget? action;
    if (dj.isDj) {
      action = TextButton.icon(
        onPressed: () => dj.stopDjing(),
        icon: const Icon(Icons.logout_rounded, size: 16),
        label: const Text('Stop DJing'),
      );
    } else if (dj.isJoining) {
      action = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
              dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          if (dj.djIdentity != dj.selfIdentity)
            TextButton(
                onPressed: () => dj.stopDjing(), child: const Text('No thanks')),
        ],
      );
    } else if (dj.caps.canDj) {
      action = dj.hasRequested
          ? TextButton(
              onPressed: () => dj.requestDj(false),
              child: const Text('$djHandEmoji Asked · Cancel'),
            )
          : TextButton.icon(
              onPressed: () => dj.requestDj(true),
              icon: const Icon(Icons.back_hand_outlined, size: 16),
              label: const Text('Ask for the decks'),
            );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              tiamat.Avatar(
                  radius: 16,
                  image: member.avatar,
                  placeholderColor: member.defaultColor,
                  placeholderText: member.displayName),
              Positioned(
                right: -4,
                bottom: -4,
                child: VinylDisc(
                    size: 16, spinning: dj.isPlaying && !dj.isBuffering),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: tiamat.Text.labelEmphasised(line,
                overflow: TextOverflow.ellipsis),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}

class _Requests extends StatelessWidget {
  const _Requests({required this.dj, required this.memberOf});

  final DjSession dj;
  final Member Function(String userId) memberOf;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              const tiamat.Text.labelLow('$djHandEmoji Asking for the decks'),
              for (final identity in dj.requests)
                Builder(builder: (context) {
                  final member = memberOf(djUserIdOf(identity));
                  final canPass =
                      dj.passTarget == null && dj.capsOf(identity)?.canDj == true;
                  return Row(
                    spacing: 10,
                    children: [
                      tiamat.Avatar(
                          radius: 12,
                          image: member.avatar,
                          placeholderColor: member.defaultColor,
                          placeholderText: member.displayName),
                      Expanded(
                          child: tiamat.Text.label(member.displayName,
                              overflow: TextOverflow.ellipsis)),
                      TextButton(
                        onPressed: canPass ? () => dj.passTo(identity) : null,
                        child: const Text('Pass the decks'),
                      ),
                    ],
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

/// The song on the decks: sleeve and record, title, progress, controls and
/// the listener's own volume.
class _NowPlaying extends StatefulWidget {
  const _NowPlaying({required this.session, required this.dj});

  final VoipSession session;
  final DjSession dj;

  @override
  State<_NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<_NowPlaying> {
  Timer? _clock;
  double? _dragging;
  String? _draggingTrack;

  DjSession get dj => widget.dj;

  @override
  void initState() {
    super.initState();
    // The position moves on its own: redraw it a few times a second.
    _clock = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted && dj.isPlaying) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = dj.current;
    // A drag left over from the previous song means nothing for this one.
    if (_draggingTrack != null && _draggingTrack != track?.id) {
      _dragging = null;
      _draggingTrack = null;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: track == null ? _idle(context) : _playing(context, track),
      ),
    );
  }

  Widget _idle(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        const VinylDisc(size: 56, spinning: false),
        Expanded(
          child: tiamat.Text.labelLow(dj.isDj
              ? 'Nothing on the decks. Paste a link below to start the music.'
              : 'Nothing playing yet.'),
        ),
        DjMusicVolume(session: widget.session),
      ],
    );
  }

  Widget _playing(BuildContext context, DjTrack track) {
    final duration = dj.durationMs ?? track.durationMs ?? 0;
    final position = _dragging?.round() ?? dj.positionMs;
    final spinning = dj.isPlaying && !dj.isBuffering;
    final controls = dj.isDj && dj.passTarget == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Sleeve(track: track, spinning: spinning),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  tiamat.Text.labelEmphasised(track.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (track.artist != null)
                    tiamat.Text.labelLow(track.artist!,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    spacing: 6,
                    children: [
                      DjSourceChip(track.kind),
                      if (dj.isBuffering)
                        const tiamat.Text.tiny('Loading…')
                      else if (!dj.isPlaying)
                        const tiamat.Text.tiny('Paused'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: controls ? 6 : 0, disabledThumbRadius: 0),
          ),
          child: Slider(
            value: duration > 0 ? position.clamp(0, duration).toDouble() : 0,
            max: duration > 0 ? duration.toDouble() : 1,
            onChanged: controls && duration > 0 && !dj.isBuffering
                ? (v) => setState(() {
                      _dragging = v;
                      _draggingTrack = track.id;
                    })
                : null,
            onChangeEnd: controls && duration > 0 && !dj.isBuffering
                ? (v) {
                    if (_draggingTrack == dj.current?.id) dj.seek(v.round());
                    setState(() {
                      _dragging = null;
                      _draggingTrack = null;
                    });
                  }
                : null,
          ),
        ),
        Row(
          children: [
            tiamat.Text.tiny(formatDjTime(position)),
            const Spacer(),
            tiamat.Text.tiny(duration > 0 ? formatDjTime(duration) : '--:--'),
          ],
        ),
        Row(
          children: [
            if (dj.isDj) ...[
              IconButton(
                tooltip: 'Back to the start',
                icon: const Icon(Icons.replay_rounded),
                onPressed: controls && !dj.isBuffering ? () => dj.seek(0) : null,
              ),
              IconButton.filled(
                tooltip: dj.isPlaying ? 'Pause for everyone' : 'Play',
                iconSize: 28,
                icon: Icon(dj.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded),
                onPressed: controls ? dj.togglePause : null,
              ),
              IconButton(
                tooltip: dj.queue.isEmpty ? 'Stop (nothing next)' : 'Next song',
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: controls ? dj.skip : null,
              ),
            ],
            const Spacer(),
            IconButton(
              tooltip: 'Open the song page',
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              onPressed: () =>
                  LinkUtils.open(Uri.parse(track.pageUrl), context: context),
            ),
            DjMusicVolume(session: widget.session),
          ],
        ),
      ],
    );
  }
}

/// The song's art in a sleeve, with the record half out of it, turning.
class _Sleeve extends StatelessWidget {
  const _Sleeve({required this.track, required this.spinning});

  final DjTrack track;
  final bool spinning;

  static const double size = 72;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.45,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: size * 0.45,
            top: 2,
            child: VinylDisc(
              size: size - 4,
              spinning: spinning,
              label: track.thumbnail == null
                  ? null
                  : NetworkImage(track.thumbnail!),
            ),
          ),
          DjTrackArt(track: track, size: size, radius: 6, elevated: true),
        ],
      ),
    );
  }
}

class DjTrackArt extends StatelessWidget {
  const DjTrackArt(
      {required this.track,
      this.size = 40,
      this.radius = 4,
      this.elevated = false,
      super.key});

  final DjTrack track;
  final double size;
  final double radius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DjSourceChip.colorOf(track.kind),
            Color.lerp(DjSourceChip.colorOf(track.kind), Colors.black, 0.6)!,
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.music_note_rounded,
            color: Colors.white70, size: size * 0.45),
      ),
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevated
            ? const [
                BoxShadow(
                    color: Colors.black38, blurRadius: 8, offset: Offset(2, 2))
              ]
            : null,
      ),
      child: track.thumbnail == null
          ? placeholder
          : Image.network(
              track.thumbnail!,
              fit: BoxFit.cover,
              cacheWidth: (size * 2).round(),
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}

class DjSourceChip extends StatelessWidget {
  const DjSourceChip(this.kind, {super.key});

  final DjSource kind;

  static Color colorOf(DjSource kind) => switch (kind) {
        DjSource.youtube => const Color(0xFFE53935),
        DjSource.soundcloud => const Color(0xFFFF7A1A),
        DjSource.spotify => const Color(0xFF1DB954),
        DjSource.other => const Color(0xFF7E57C2),
      };

  static String nameOf(DjSource kind) => switch (kind) {
        DjSource.youtube => 'YouTube',
        DjSource.soundcloud => 'SoundCloud',
        DjSource.spotify => 'Spotify',
        DjSource.other => 'Link',
      };

  @override
  Widget build(BuildContext context) {
    final color = colorOf(kind);
    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(nameOf(kind),
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
    if (kind != DjSource.spotify) return chip;
    return Tooltip(
      message: "Spotify songs play from YouTube's closest match",
      child: chip,
    );
  }
}

/// Mute button and slider for the booth's music, for this listener only.
class DjMusicVolume extends StatefulWidget {
  const DjMusicVolume({required this.session, this.width = 88, super.key});

  final VoipSession session;
  final double width;

  @override
  State<DjMusicVolume> createState() => _DjMusicVolumeState();
}

class _DjMusicVolumeState extends State<DjMusicVolume> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = preferences.djMusicVolume.onChanged.listen((_) {
      if (mounted) setState(() {});
    });
    _liveMusicVolume.addListener(_onLive);
  }

  void _onLive() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    _liveMusicVolume.removeListener(_onLive);
    super.dispose();
  }

  void _toggleMute() {
    final volume = preferences.djMusicVolume.value;
    if (volume > 0) {
      preferences.djMusicPremuteVolume.set(volume);
      setDjMusicVolume(widget.session, 0);
    } else {
      final back = preferences.djMusicPremuteVolume.value;
      setDjMusicVolume(widget.session, back > 0 ? back : 0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final volume = (_liveMusicVolume.value ?? preferences.djMusicVolume.value)
        .clamp(0.0, maxDjMusicVolume);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: volume == 0 ? 'Unmute the music' : 'Mute the music for you',
          icon: Icon(
            volume == 0
                ? Icons.volume_off_rounded
                : volume < 0.5
                    ? Icons.volume_down_rounded
                    : Icons.volume_up_rounded,
            size: 20,
          ),
          onPressed: _toggleMute,
        ),
        SizedBox(
          width: widget.width,
          child: Tooltip(
            message: 'Music volume, only for you (${(volume * 100).round()}%)',
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                overlayShape: SliderComponentShape.noOverlay,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: volume,
                max: maxDjMusicVolume,
                onChanged: (v) =>
                    setDjMusicVolume(widget.session, v, save: false),
                onChangeEnd: (v) => setDjMusicVolume(widget.session, v),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Where the DJ pastes links.
class _AddBar extends StatefulWidget {
  const _AddBar({required this.dj, required this.enabled});

  final DjSession dj;
  final bool enabled;

  @override
  State<_AddBar> createState() => _AddBarState();
}

class _AddBarState extends State<_AddBar> {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  List<DjLink> _links = const [];

  @override
  void initState() {
    super.initState();
    _text.addListener(() {
      final links = DjLinks.parseAll(_text.text);
      if (links.length != _links.length ||
          (links.isNotEmpty && links.first.url != _links.firstOrNull?.url)) {
        setState(() => _links = links);
      }
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add({bool next = false}) {
    if (_links.isEmpty || !widget.enabled) return;
    // Kept when nothing was taken (the booth changed hands meanwhile).
    if (widget.dj.addLinks(_text.text, next: next) == 0) return;
    _text.clear();
    _focus.requestFocus();
  }

  String _describe(List<DjLink> links) {
    if (links.length > 1) return '${links.length} links';
    return switch (links.single.type) {
      DjLinkType.youtubeVideo => 'YouTube video',
      DjLinkType.youtubePlaylist => 'YouTube playlist, every song',
      DjLinkType.soundcloudTrack => 'SoundCloud track',
      DjLinkType.soundcloudSet => 'SoundCloud set, every song',
      DjLinkType.spotifyTrack => 'Spotify song, played from YouTube',
      DjLinkType.spotifyAlbum => 'Spotify album, played from YouTube',
      DjLinkType.spotifyPlaylist =>
        'Spotify playlist (first 50 songs), played from YouTube',
      DjLinkType.other => 'Link, if yt-dlp knows the site',
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pending = widget.dj.pendingAdds;
    final canAdd = widget.enabled && _links.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        CallbackShortcuts(
          // Enter adds, Shift+Enter plays next; Ctrl+Enter makes a new line
          // for pasting several links by hand.
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): _add,
            const SingleActivator(LogicalKeyboardKey.enter, shift: true): () =>
                _add(next: true),
          },
          child: TextField(
            controller: _text,
            focusNode: _focus,
            minLines: 1,
            maxLines: 3,
            enabled: widget.enabled,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: scheme.surfaceContainerHighest,
              hintText: widget.enabled
                  ? 'Paste a YouTube, SoundCloud or Spotify link'
                  : 'Locked while the decks change hands',
              prefixIcon: const Icon(Icons.link_rounded, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Play next (Shift+Enter)',
                    icon: const Icon(Icons.low_priority_rounded, size: 20),
                    onPressed: canAdd ? () => _add(next: true) : null,
                  ),
                  IconButton(
                    tooltip: 'Add to the queue (Enter)',
                    icon: const Icon(Icons.playlist_add_rounded, size: 22),
                    onPressed: canAdd ? _add : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_links.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: tiamat.Text.tiny(_describe(_links)),
          ),
        if (pending.isNotEmpty)
          Row(
            spacing: 8,
            children: [
              const SizedBox.square(
                  dimension: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5)),
              DjSourceChip(pending.first.link.source),
              Expanded(
                child: tiamat.Text.tiny(
                    pending.length == 1
                        ? 'Adding ${pending.single.link.url}'
                        : 'Adding ${pending.length} links…',
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
      ],
    );
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({required this.dj, required this.editable});

  final DjSession dj;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final queue = dj.queue;
    final total = queue.fold<int>(0, (sum, t) => sum + (t.durationMs ?? 0));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: tiamat.Text.labelLow(queue.isEmpty
                ? 'Up next'
                : 'Up next · ${queue.length} '
                    '${queue.length == 1 ? 'song' : 'songs'}'
                    '${total > 0 ? ' · ${formatDjTime(total)}' : ''}'),
          ),
          if (editable && queue.length > 1)
            IconButton(
              tooltip: 'Shuffle',
              icon: const Icon(Icons.shuffle_rounded, size: 18),
              onPressed: dj.shuffle,
            ),
          if (editable && queue.isNotEmpty)
            IconButton(
              tooltip: 'Clear the queue',
              icon: const Icon(Icons.clear_all_rounded, size: 20),
              onPressed: () async {
                final yes = await AdaptiveDialog.confirmation(context,
                    title: 'Clear the queue?',
                    prompt: 'Removes ${queue.length} songs. The one playing '
                        'keeps playing.',
                    confirmationText: 'Clear',
                    cancelText: 'Keep',
                    dangerous: true);
                if (yes == true) dj.clearQueue();
              },
            ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatefulWidget {
  const _QueueRow({
    required this.dj,
    required this.track,
    required this.index,
    required this.editable,
    required this.addedBy,
    super.key,
  });

  final DjSession dj;
  final DjTrack track;
  final int index;
  final bool editable;
  final Member addedBy;

  @override
  State<_QueueRow> createState() => _QueueRowState();
}

class _QueueRowState extends State<_QueueRow> {
  bool _hover = false;

  DjTrack get track => widget.track;

  List<tiamat.ContextMenuItem> _items(BuildContext context) => [
        if (widget.editable) ...[
          tiamat.ContextMenuItem(
              text: 'Play now',
              icon: Icons.play_arrow_rounded,
              onPressed: () => widget.dj.playNow(track.id)),
          if (widget.index > 0)
            tiamat.ContextMenuItem(
                text: 'Play next',
                icon: Icons.low_priority_rounded,
                onPressed: () => widget.dj.playNext(track.id)),
          tiamat.ContextMenuItem(
              text: 'Edit',
              icon: Icons.edit_rounded,
              onPressed: () => editDjTrack(context, widget.dj, track)),
        ],
        tiamat.ContextMenuItem(
            text: 'Open the song page',
            icon: Icons.open_in_new_rounded,
            onPressed: () =>
                LinkUtils.open(Uri.parse(track.pageUrl), context: context)),
        if (widget.editable)
          tiamat.ContextMenuItem(
              text: 'Remove',
              icon: Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
              onPressed: () => widget.dj.remove(track.id)),
      ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Without a mouse there is no hover: the handle is always there.
    final showHandle =
        widget.editable && (_hover || MediaQuery.of(context).mobile);
    final number = SizedBox(
      width: 28,
      child: Center(
        child: showHandle
            ? ReorderableDragStartListener(
                index: widget.index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Tooltip(
                    message: 'Drag to reorder',
                    child: Icon(Icons.drag_indicator_rounded,
                        size: 18, color: scheme.outline),
                  ),
                ),
              )
            : tiamat.Text.tiny('${widget.index + 1}'),
      ),
    );

    final row = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        color: _hover ? scheme.surfaceContainerHigh : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        child: Row(
          spacing: 10,
          children: [
            number,
            DjTrackArt(track: track, size: 40),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  tiamat.Text.label(track.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Row(
                    spacing: 6,
                    children: [
                      DjSourceChip(track.kind),
                      Flexible(
                        child: tiamat.Text.tiny(
                          [
                            if (track.artist != null) track.artist!,
                            'added by ${widget.addedBy.displayName}',
                          ].join(' · '),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (track.durationMs != null)
              tiamat.Text.tiny(formatDjTime(track.durationMs!)),
            if (widget.editable)
              SizedBox(
                width: 32,
                // Not there while hidden: no clicking or tabbing to it.
                child: Visibility(
                  visible: _hover || MediaQuery.of(context).mobile,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: IconButton(
                    tooltip: 'Remove',
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => widget.dj.remove(track.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return AdaptiveContextMenu(items: _items(context), child: row);
  }
}

/// Lets the DJ fix a queued song: another link (resolved again) or another
/// title.
Future<void> editDjTrack(
    BuildContext context, DjSession dj, DjTrack track) async {
  final result = await showDialog<(String, String)>(
    context: context,
    builder: (context) => _EditTrackDialog(track: track),
  );
  if (result == null) return;
  // A new link is looked up in the add bar's "Adding…" line, and a failure
  // arrives as a booth notice.
  dj.editTrack(track.id, link: result.$1, title: result.$2);
}

/// Owns its text fields, which outlive the pop while the dialog animates
/// out.
class _EditTrackDialog extends StatefulWidget {
  const _EditTrackDialog({required this.track});

  final DjTrack track;

  @override
  State<_EditTrackDialog> createState() => _EditTrackDialogState();
}

class _EditTrackDialogState extends State<_EditTrackDialog> {
  late final TextEditingController _link =
      TextEditingController(text: widget.track.pageUrl);
  late final TextEditingController _title =
      TextEditingController(text: widget.track.title);

  @override
  void dispose() {
    _link.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit song'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            TextField(
              controller: _title,
              maxLength: DjTrack.maxText,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _link,
              decoration: const InputDecoration(
                  labelText: 'Link',
                  helperText: 'YouTube, SoundCloud or Spotify'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, (_link.text, _title.text)),
            child: const Text('Save')),
      ],
    );
  }
}

/// Compact "now playing" line for the top of the call, opening the booth.
class DjNowPlayingPill extends StatelessWidget {
  const DjNowPlayingPill({required this.dj, required this.onTap, super.key});

  final DjSession dj;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dj,
      builder: (context, _) {
        final track = dj.current;
        // While someone DJs, even between songs: it is how listeners find
        // the booth.
        if (dj.isDisposed || dj.djIdentity == null || dj.isVacant) {
          return const SizedBox.shrink();
        }
        final line = track == null
            ? 'DJ booth · nothing playing'
            : track.artist == null
                ? track.title
                : '${track.title} · ${track.artist}';
        return Material(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    VinylDisc(
                        size: 22,
                        spinning: dj.isPlaying && !dj.isBuffering,
                        label: track?.thumbnail == null
                            ? null
                            : NetworkImage(track!.thumbnail!)),
                    Flexible(
                      child: Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    if (track != null && !dj.isPlaying)
                      const Icon(Icons.pause_rounded,
                          size: 16, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
