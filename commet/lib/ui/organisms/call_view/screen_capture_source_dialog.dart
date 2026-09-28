// Picking what to share: screens and windows on tabs of their own, cards of
// one size with their live thumbnail, a selection to confirm with the Share
// button (or a double click, or Enter), and whether the system audio goes
// with it. Thumbnails refresh while the picker is open, and windows opened
// or closed meanwhile come and go.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class ScreenCaptureDialogResult {
  final DesktopCapturerSource source;
  final bool doNotShareAudio;

  const ScreenCaptureDialogResult({
    required this.source,
    this.doNotShareAudio = false,
  });

  bool get captureAudio => !doNotShareAudio;
}

/// Where the picker gets its sources and hears about changes to them.
abstract class ScreenSourceFeed {
  /// A window opened.
  Stream<DesktopCapturerSource> get added;

  /// A window closed, or a screen went away.
  Stream<DesktopCapturerSource> get removed;

  /// A source has a new thumbnail or name.
  Stream<DesktopCapturerSource> get changed;

  /// Asks for fresh thumbnails, and for windows opened or closed since.
  Future<void> refresh();
}

/// The system's screens and windows, through flutter-webrtc.
class DesktopCapturerFeed implements ScreenSourceFeed {
  DesktopCapturerFeed(this.types);

  final List<SourceType> types;

  @override
  Stream<DesktopCapturerSource> get added => desktopCapturer.onAdded.stream;

  @override
  Stream<DesktopCapturerSource> get removed => desktopCapturer.onRemoved.stream;

  @override
  Stream<DesktopCapturerSource> get changed => _merge([
        desktopCapturer.onThumbnailChanged.stream,
        desktopCapturer.onNameChanged.stream,
      ]);

  @override
  Future<void> refresh() async {
    await desktopCapturer.updateSources(types: types);
  }
}

/// One stream of what [streams] carry, listened to while it is.
Stream<T> _merge<T>(List<Stream<T>> streams) {
  final subs = <StreamSubscription<T>>[];
  late final StreamController<T> controller;
  controller = StreamController<T>.broadcast(
    onListen: () {
      for (final stream in streams) {
        subs.add(stream.listen(controller.add));
      }
    },
    onCancel: () {
      for (final sub in subs) {
        sub.cancel();
      }
      subs.clear();
    },
  );
  return controller.stream;
}

class ScreenCaptureSourceDialog extends StatefulWidget {
  const ScreenCaptureSourceDialog(this.sources, this.feed,
      {this.refreshEvery = const Duration(seconds: 2), super.key});

  final List<DesktopCapturerSource> sources;
  final ScreenSourceFeed feed;

  /// How often thumbnails are refreshed while the picker is open.
  final Duration refreshEvery;

  @override
  State<ScreenCaptureSourceDialog> createState() =>
      _ScreenCaptureSourceDialogState();
}

class _ScreenCaptureSourceDialogState extends State<ScreenCaptureSourceDialog>
    with SingleTickerProviderStateMixin {
  /// By id, in the order they came.
  final Map<String, DesktopCapturerSource> _sources = {};
  final List<StreamSubscription> _subs = [];
  late final TabController _tabs;
  Timer? _refresh;
  bool _refreshing = false;
  String? _selected;
  bool _shareAudio = true;

  /// The last click on a card, to tell a double click. By hand: a
  /// GestureDetector with onDoubleTap holds every single click back until
  /// it knows no second one is coming, and picking would feel slow.
  (String, DateTime)? _lastClick;

  static const doubleClick = Duration(milliseconds: 400);

  void _clicked(String id) {
    final now = DateTime.now();
    final last = _lastClick;
    if (last != null &&
        last.$1 == id &&
        now.difference(last.$2) < doubleClick) {
      _lastClick = null;
      _share(id);
      return;
    }
    _lastClick = (id, now);
    setState(() => _selected = id);
  }

  List<DesktopCapturerSource> _ofType(SourceType type) =>
      _sources.values.where((s) => s.type == type).toList();

  @override
  void initState() {
    super.initState();
    for (final source in widget.sources) {
      _sources[source.id] = source;
    }
    final screens = _ofType(SourceType.Screen);
    final windows = _ofType(SourceType.Window);
    // Screens first; windows when there are only windows.
    _tabs = TabController(
        length: 2, vsync: this, initialIndex: screens.isEmpty ? 1 : 0);
    // With one screen there is nothing to choose: it is ready to share.
    if (screens.length == 1) {
      _selected = screens.single.id;
    } else if (screens.isEmpty && windows.length == 1) {
      _selected = windows.single.id;
    }

    _subs
      ..add(widget.feed.added.listen((source) {
        if (mounted) setState(() => _sources[source.id] = source);
      }))
      ..add(widget.feed.removed.listen((source) {
        if (!mounted) return;
        setState(() {
          _sources.remove(source.id);
          if (_selected == source.id) _selected = null;
        });
      }))
      ..add(widget.feed.changed.listen((source) {
        if (!mounted || !_sources.containsKey(source.id)) return;
        setState(() => _sources[source.id] = source);
      }));

    _refresh = Timer.periodic(widget.refreshEvery, (_) async {
      if (_refreshing) return;
      _refreshing = true;
      try {
        await widget.feed.refresh();
      } catch (_) {
        // Thumbnails stay as they were.
      } finally {
        _refreshing = false;
      }
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    for (final sub in _subs) {
      sub.cancel();
    }
    _tabs.dispose();
    super.dispose();
  }

  void _share([String? id]) {
    final source = _sources[id ?? _selected];
    if (source == null) return;
    Navigator.of(context).pop(ScreenCaptureDialogResult(
      source: source,
      doNotShareAudio: !_shareAudio,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screens = _ofType(SourceType.Screen);
    final windows = _ofType(SourceType.Window);
    final selected = _sources[_selected];
    // As big as it comes, within a window that may be small.
    final screen = MediaQuery.sizeOf(context);
    final width = (screen.width - 64).clamp(320.0, 760.0);
    final height = (screen.height - 180).clamp(300.0, 560.0);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _share,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _share,
      },
      child: Focus(
        autofocus: true,
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TabBar(
                controller: _tabs,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.monitor_outlined, size: 20),
                    text: 'Screens (${screens.length})',
                    iconMargin: const EdgeInsets.only(bottom: 2),
                  ),
                  Tab(
                    icon: const Icon(Icons.web_asset_outlined, size: 20),
                    text: 'Windows (${windows.length})',
                    iconMargin: const EdgeInsets.only(bottom: 2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _grid(screens,
                        empty: 'No screens to share',
                        icon: Icons.monitor_outlined),
                    _grid(windows,
                        empty: 'No windows to share',
                        icon: Icons.web_asset_outlined),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                child: Row(
                  children: [
                    Switch(
                      value: _shareAudio,
                      onChanged: (value) => setState(() => _shareAudio = value),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: tiamat.Text.label('Share system audio',
                          overflow: TextOverflow.ellipsis),
                    ),
                    const Spacer(),
                    if (selected != null)
                      Flexible(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            selected.name,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                color: scheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      key: const ValueKey('screen-share-go'),
                      onPressed: selected == null ? null : _share,
                      icon: const Icon(Icons.screen_share_rounded, size: 18),
                      label: const Text('Share'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid(List<DesktopCapturerSource> sources,
      {required String empty, required IconData icon}) {
    if (sources.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Icon(icon,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            tiamat.Text.labelLow(empty),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // A 16:9 thumbnail and a line of text under it.
        childAspectRatio: 16 / 11.5,
      ),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        return ScreenCaptureSourceCard(
          source,
          key: ValueKey(source.id),
          selected: source.id == _selected,
          onTap: () => _clicked(source.id),
        );
      },
    );
  }
}

/// A screen or window: its thumbnail at one size, its name under it.
class ScreenCaptureSourceCard extends StatefulWidget {
  const ScreenCaptureSourceCard(this.source,
      {required this.selected, required this.onTap, super.key});

  final DesktopCapturerSource source;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<ScreenCaptureSourceCard> createState() =>
      _ScreenCaptureSourceCardState();
}

class _ScreenCaptureSourceCardState extends State<ScreenCaptureSourceCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumbnail = widget.source.thumbnail;
    final border = widget.selected
        ? scheme.primary
        : _hover
            ? scheme.outline
            : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          selected: widget.selected,
          label: widget.source.name,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border, width: 2.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (thumbnail != null && thumbnail.isNotEmpty)
                        Image.memory(thumbnail,
                            fit: BoxFit.contain, gaplessPlayback: true)
                      else
                        const Center(
                          child: SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      if (widget.selected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                                color: scheme.primary, shape: BoxShape.circle),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(Icons.check_rounded,
                                  size: 16, color: scheme.onPrimary),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Row(
                spacing: 6,
                children: [
                  Icon(
                    widget.source.type == SourceType.Screen
                        ? Icons.monitor_outlined
                        : Icons.web_asset_outlined,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Text(
                      widget.source.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: widget.selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: widget.selected
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
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
