// Soundboard popover (Discord-style): search, favorites, a rail with one
// entry per Space, and collapsible sections holding a 3-column grid.
//
// Pure Flutter (no platform plugins) so it behaves the same on web.
import 'dart:async';

import 'package:commet/client/components/soundboard/soundboard_catalog.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/ui/atoms/anchored_popover.dart';
import 'package:commet/ui/molecules/soundboard_emoji_picker.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_favorites.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

/// One Space whose sounds can be played in the current call.
class SoundboardSource {
  final String id;
  final String name;
  final ImageProvider? avatar;
  final Color color;
  final SoundboardCatalog catalog;

  const SoundboardSource({
    required this.id,
    required this.name,
    required this.color,
    required this.catalog,
    this.avatar,
  });
}

class SoundboardPopover extends StatefulWidget {
  final List<SoundboardSource> sources;
  final SoundboardFavorites favorites;
  final ValueChanged<String> onPlay;
  final double volume01;
  final ValueChanged<double> onVolumeChanged;

  /// Resolves custom Space emoji images; without it their fallback shows.
  final SoundboardEmojiImageResolver? imageFor;

  const SoundboardPopover({
    super.key,
    required this.sources,
    required this.favorites,
    required this.onPlay,
    required this.volume01,
    required this.onVolumeChanged,
    this.imageFor,
  });

  static const double width = 540;
  static const double height = 440;

  @override
  State<SoundboardPopover> createState() => _SoundboardPopoverState();
}

class _Section {
  final String key;
  final String title;
  final SoundboardSource? source;
  final List<SoundboardSound> sounds;
  const _Section(this.key, this.title, this.source, this.sounds);

  bool get isFavorites => source == null;
}

class _SoundboardPopoverState extends State<SoundboardPopover> {
  static const favoritesKey = 'favorites';
  static const columns = 3;

  /// Collapsed sections, kept for the app session so reopening the
  /// popover looks the same.
  static final Set<String> _collapsed = {};

  String _query = '';
  final List<StreamSubscription> _subs = [];
  final Map<String, GlobalKey> _sectionKeys = {};

  @override
  void initState() {
    super.initState();
    widget.favorites.addListener(_refresh);
    _listenToCatalogs();
  }

  @override
  void didUpdateWidget(SoundboardPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.favorites != widget.favorites) {
      oldWidget.favorites.removeListener(_refresh);
      widget.favorites.addListener(_refresh);
    }
    if (oldWidget.sources != widget.sources) _listenToCatalogs();
  }

  @override
  void dispose() {
    widget.favorites.removeListener(_refresh);
    _cancelCatalogSubs();
    super.dispose();
  }

  void _listenToCatalogs() {
    _cancelCatalogSubs();
    for (final source in widget.sources) {
      _subs.add(source.catalog.onChanged.listen((_) => _refresh()));
    }
  }

  void _cancelCatalogSubs() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  SoundboardSound? _findSound(String soundId) {
    for (final source in widget.sources) {
      final sound = source.catalog.getById(soundId);
      if (sound != null) return sound;
    }
    return null;
  }

  List<_Section> _sections() {
    final query = _query.trim().toLowerCase();
    bool matches(SoundboardSound s) =>
        query.isEmpty || s.name.toLowerCase().contains(query);

    final favorites =
        widget.favorites.ids.map(_findSound).nonNulls.where(matches).toList();

    return [
      _Section(favoritesKey, 'Favorites', null, favorites),
      for (final source in widget.sources)
        _Section(source.id, source.name, source,
            source.catalog.sounds.where(matches).toList()),
    ].where((s) => s.sounds.isNotEmpty).toList();
  }

  GlobalKey _keyFor(String section) =>
      _sectionKeys.putIfAbsent(section, () => GlobalKey());

  void _jumpTo(String section) {
    setState(() => _collapsed.remove(section));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _sectionKeys[section]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(context,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  void _toggleCollapsed(String section) {
    setState(() {
      if (!_collapsed.remove(section)) _collapsed.add(section);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections();
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: SoundboardPopover.width,
      height: SoundboardPopover.height,
      child: Material(
        color: colors.surfaceContainer,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _rail(sections),
            Expanded(
              child: Column(
                children: [
                  _searchBar(),
                  Expanded(
                    child: sections.isEmpty
                        ? Center(
                            child: tiamat.Text.labelLow(
                              widget.sources
                                      .every((s) => s.catalog.sounds.isEmpty)
                                  ? 'No sounds yet. An admin can add some in Space settings.'
                                  : 'No sounds found',
                            ),
                          )
                        : _body(sections),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Find the perfect sound',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          AnchoredPopover(
            alignment: PopoverAlignment.end,
            anchorBuilder: (context, open, toggle) => IconButton(
              tooltip: 'Sound effects volume',
              isSelected: open,
              icon: Icon(
                  widget.volume01 <= 0 ? Icons.volume_off : Icons.volume_up),
              onPressed: toggle,
            ),
            popoverBuilder: (context, close) => _VolumePopover(
              volume01: widget.volume01,
              onChanged: widget.onVolumeChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// One entry per visible section, so the rail always matches the body.
  Widget _rail(List<_Section> sections) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 52,
      color: colors.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final section in sections)
            _RailEntry(
              tooltip: section.title,
              onTap: () => _jumpTo(section.key),
              child: section.isFavorites
                  ? Icon(Icons.star, color: colors.primary, size: 20)
                  : tiamat.Avatar(
                      radius: 16,
                      image: section.source!.avatar,
                      placeholderText: section.title,
                      placeholderColor: section.source!.color,
                    ),
            ),
        ],
      ),
    );
  }

  Widget _body(List<_Section> sections) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in sections) _section(section),
        ],
      ),
    );
  }

  Widget _section(_Section section) {
    final collapsed = _collapsed.contains(section.key);
    final colors = Theme.of(context).colorScheme;
    return Column(
      key: _keyFor(section.key),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _toggleCollapsed(section.key),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
            child: Row(
              children: [
                if (section.isFavorites)
                  Icon(Icons.star, size: 14, color: colors.primary)
                else
                  tiamat.Avatar(
                    radius: 8,
                    image: section.source!.avatar,
                    placeholderText: section.title,
                    placeholderColor: section.source!.color,
                  ),
                const SizedBox(width: 6),
                Flexible(
                  child: tiamat.Text.labelLow(
                    section.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  turns: collapsed ? -0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.expand_more,
                      size: 16, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        if (!collapsed) _grid(section.sounds),
      ],
    );
  }

  Widget _grid(List<SoundboardSound> sounds) {
    const spacing = 6.0;
    return Column(
      children: [
        for (var row = 0; row < sounds.length; row += columns)
          Padding(
            padding: const EdgeInsets.only(bottom: spacing),
            child: Row(
              children: [
                for (var col = 0; col < columns; col++) ...[
                  if (col > 0) const SizedBox(width: spacing),
                  Expanded(
                    child: row + col < sounds.length
                        ? _tile(sounds[row + col])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _tile(SoundboardSound sound) {
    return _SoundTile(
      sound: sound,
      favorite: widget.favorites.contains(sound.soundId),
      onPlay: () => widget.onPlay(sound.soundId),
      onToggleFavorite: () => widget.favorites.toggle(sound.soundId),
      imageFor: widget.imageFor,
    );
  }
}

class _VolumePopover extends StatefulWidget {
  final double volume01;
  final ValueChanged<double> onChanged;

  const _VolumePopover({required this.volume01, required this.onChanged});

  @override
  State<_VolumePopover> createState() => _VolumePopoverState();
}

class _VolumePopoverState extends State<_VolumePopover> {
  late double _volume = widget.volume01.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 260,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const tiamat.Text.labelLow('Sound effects volume'),
              Row(
                children: [
                  Expanded(
                    child: tiamat.Slider(
                      key: const ValueKey('soundboard-volume-slider'),
                      value: _volume,
                      onChanged: (v) {
                        setState(() => _volume = v);
                        widget.onChanged(v);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: tiamat.Text.labelLow('${(_volume * 100).round()}%'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailEntry extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  const _RailEntry({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(height: 44, child: Center(child: child)),
      ),
    );
  }
}

class _SoundTile extends StatefulWidget {
  final SoundboardSound sound;
  final bool favorite;
  final VoidCallback onPlay;
  final VoidCallback onToggleFavorite;
  final SoundboardEmojiImageResolver? imageFor;

  const _SoundTile({
    required this.sound,
    required this.favorite,
    required this.onPlay,
    required this.onToggleFavorite,
    this.imageFor,
  });

  @override
  State<_SoundTile> createState() => _SoundTileState();
}

class _SoundTileState extends State<_SoundTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sound = widget.sound;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Material(
          color: _hovered
              ? colors.surfaceContainerHighest
              : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            // Instant feedback: animation + local play happen before any
            // network round-trip.
            onTap: widget.onPlay,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onLongPress: widget.onToggleFavorite,
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  SoundboardEmojiView(sound.emoji,
                      image: widget.imageFor?.call(sound.emoji), size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: tiamat.Text.label(
                      sound.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Kept in the tree (and tappable) while hidden so touch
                  // users can still reach it; long-press works too.
                  Opacity(
                    opacity: widget.favorite || _hovered ? 1 : 0,
                    child: IconButton(
                      tooltip: widget.favorite
                          ? 'Remove ${sound.name} from favorites'
                          : 'Add ${sound.name} to favorites',
                      iconSize: 14,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints.tightFor(width: 26, height: 26),
                      color: widget.favorite ? colors.primary : null,
                      icon: Icon(
                          widget.favorite ? Icons.star : Icons.star_border),
                      onPressed: widget.onToggleFavorite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
