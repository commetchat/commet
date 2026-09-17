import 'dart:ui';

import 'package:commet/client/components/gif/gif_component.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import '../../utils/debounce.dart';
import '../../client/components/gif/gif_search_result.dart';

class GifPicker extends StatefulWidget {
  const GifPicker(
      {super.key,
      this.gifPicked,
      this.search,
      this.trending,
      this.focus,
      this.favorites = const [],
      this.favoritePicked,
      this.onUnfavoriteGif,
      this.onDismiss,
      this.placeholderText = "Search Gif"});
  final List<FavoriteGif> favorites;
  final Future<void> Function(GifSearchResult gif)? gifPicked;
  final Future<void> Function(FavoriteGif gif)? favoritePicked;
  final Future<void> Function(FavoriteGif gif)? onUnfavoriteGif;
  final Future<GifSearchPage> Function(String query, {String? pos})? search;
  final Future<GifSearchPage> Function({String? pos})? trending;
  final FocusNode? focus;

  /// Called when escape is pressed inside the picker
  final void Function()? onDismiss;

  final String placeholderText;

  @override
  State<GifPicker> createState() => _GifPickerState();

  static String get promptUnfavoriteGif => Intl.message(
        "Unfavorite GIF",
        desc: "Prompt the user remove a gif from favorites",
        name: "promptUnfavoriteGif",
      );

  static String get labelGifPickerFavorites => Intl.message(
        "Favorites",
        desc: "Header above the favorite gifs in the gif picker",
        name: "labelGifPickerFavorites",
      );

  static String get labelGifPickerTrending => Intl.message(
        "Trending",
        desc: "Header above the trending gifs in the gif picker",
        name: "labelGifPickerTrending",
      );

  static String get labelGifPickerEmpty => Intl.message(
        "Type to search for GIFs",
        desc: "Shown in the gif picker when there is nothing to show yet",
        name: "labelGifPickerEmpty",
      );

  static String get labelGifPickerNoResults => Intl.message(
        "No GIFs found",
        desc: "Shown in the gif picker when a search has no results",
        name: "labelGifPickerNoResults",
      );

  static String get labelGifPickerError => Intl.message(
        "Couldn't load GIFs",
        desc: "Shown in the gif picker when loading gifs failed",
        name: "labelGifPickerError",
      );

  static String get labelGifPickerSendFailed => Intl.message(
        "Couldn't send the GIF",
        desc: "Shown when sending a gif from the gif picker failed",
        name: "labelGifPickerSendFailed",
      );

  static String get promptGifPickerRetry => Intl.message(
        "Retry",
        desc: "Button to retry loading gifs after an error",
        name: "promptGifPickerRetry",
      );
}

// One scrollable list of results (trending, or the current search)
class _GifFeed {
  final String query;
  final List<GifSearchResult> results = [];
  final Set<String> ids = {};
  String? next;
  bool loading = false;
  bool loadingMore = false;
  Object? error;

  _GifFeed(this.query);
}

class _GifPickerState extends State<GifPicker> {
  bool sending = false;

  // Shown inside the picker: the chat has no Scaffold for a snack bar
  bool sendFailed = false;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Debouncer debouce = Debouncer(delay: const Duration(milliseconds: 500));

  _GifFeed trendingFeed = _GifFeed("");
  _GifFeed? searchFeed;

  _GifFeed get currentFeed => searchFeed ?? trendingFeed;

  @override
  void initState() {
    _textController.addListener(onTextChanged);

    // Not on mobile: the keyboard would cover most of the panel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && MediaQuery.of(context).desktop) {
        widget.focus?.requestFocus();
      }
    });

    load(trendingFeed);

    super.initState();
  }

  @override
  void dispose() {
    debouce.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String prevText = "";
  void onTextChanged() {
    var text = _textController.text.trim();
    if (text == prevText) {
      return;
    }

    prevText = text;

    if (text.isNotEmpty) {
      // Keep showing the previous results until the debounce fires, so the
      // grid does not flash to a spinner on every keystroke
      debouce.run(() {
        if (!mounted) return;
        var feed = _GifFeed(text);
        searchFeed = feed;
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
        load(feed);
      });
      return;
    } else {
      debouce.cancel();
      setState(() {
        searchFeed = null;
      });
    }

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> load(_GifFeed feed, {bool more = false}) async {
    if (more && (feed.next == null || feed.loading || feed.loadingMore)) {
      return;
    }
    if (!mounted) return;

    setState(() {
      if (more) {
        feed.loadingMore = true;
      } else {
        feed.loading = true;
        feed.error = null;
      }
    });

    var failed = false;
    try {
      var pos = more ? feed.next : null;
      var page = feed.query.isEmpty
          ? await widget.trending?.call(pos: pos)
          : await widget.search?.call(feed.query, pos: pos);

      page ??= GifSearchPage.empty;

      int added = 0;
      for (var result in page.results) {
        if (result.id == null || feed.ids.add(result.id!)) {
          feed.results.add(result);
          added += 1;
        }
      }

      // Stop paging if the cursor didn't give us anything new
      feed.next = added == 0 ? null : page.next;
    } catch (e, s) {
      Log.onError(e, s, content: "Failed to load gifs");
      failed = true;
      // A failed next page keeps its cursor: scrolling again retries it
      if (!more) {
        feed.error = e;
        feed.next = null;
      }
    }

    feed.loading = false;
    feed.loadingMore = false;

    if (!mounted) return;
    setState(() {});

    // Not after a failure, that would retry in a loop while offline
    if (failed) return;

    // Keep loading if the first page doesn't fill the view
    WidgetsBinding.instance.addPostFrameCallback((_) => maybeLoadMore());
  }

  void maybeLoadMore() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 400) {
      load(currentFeed, more: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (widget.onDismiss != null &&
            event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onDismiss!.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      // Clicking the grid or the scrollbar must not unfocus the search field:
      // escape and typing only reach the picker through it
      child: TextFieldTapRegion(
          child: Stack(children: [
        buildContent(context),
        IgnorePointer(
          ignoring: !sending,
          child: AnimatedOpacity(
            opacity: sending ? 1 : 0,
            duration: const Duration(milliseconds: 100),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: 2, sigmaY: 2, tileMode: TileMode.repeated),
              child: Container(
                color: Colors.black.withAlpha(100),
                child: const Center(
                    child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(),
                )),
              ),
            ),
          ),
        ),
      ])),
    );
  }

  Widget buildContent(BuildContext context) {
    if (BuildConfig.MOBILE) {
      return Column(children: [
        buildSearchBar(),
        if (sendFailed) buildSendError(),
        buildResults(context)
      ]);
    } else {
      return Column(children: [
        buildResults(context),
        if (sendFailed) buildSendError(),
        buildSearchBar()
      ]);
    }
  }

  Widget buildSendError() {
    return Padding(
      key: const ValueKey("gifPicker_sendError"),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        spacing: 8,
        children: [
          Icon(Icons.error_outline,
              size: 16, color: ColorScheme.of(context).error),
          Expanded(
              child: tiamat.Text.labelLow(GifPicker.labelGifPickerSendFailed)),
        ],
      ),
    );
  }

  Widget buildSearchBar() {
    return tiamat.Tile.low(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
            height: BuildConfig.DESKTOP ? 30 : null,
            child: TextField(
              controller: _textController,
              focusNode: widget.focus,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                  icon: const Icon(Icons.search),
                  isDense: true,
                  border: InputBorder.none,
                  hintText: widget.placeholderText),
            )),
      ),
    );
  }

  Widget buildResults(BuildContext context) {
    var feed = currentFeed;
    var slivers = <Widget>[];

    if (feed == trendingFeed) {
      bool hasFavorites = widget.favorites.isNotEmpty;
      bool hasTrending = feed.results.isNotEmpty;

      if (hasFavorites) {
        if (hasTrending) slivers.add(header(GifPicker.labelGifPickerFavorites));
        slivers.add(grid(
            widget.favorites.length, (i) => favoriteTile(widget.favorites[i])));
      }

      if (hasTrending) {
        if (hasFavorites) slivers.add(header(GifPicker.labelGifPickerTrending));
        slivers
            .add(grid(feed.results.length, (i) => resultTile(feed.results[i])));
      }

      if (hasFavorites && !hasTrending) {
        // Below the favorites, so a failed trending request can be retried
        if (feed.loading) {
          slivers.add(const SliverToBoxAdapter(
              child: Padding(
            padding: EdgeInsets.all(8),
            child: Center(
                child: SizedBox(
                    width: 24, height: 24, child: CircularProgressIndicator())),
          )));
        } else if (feed.error != null) {
          slivers.add(SliverToBoxAdapter(child: errorView(feed)));
        }
      }

      if (!hasFavorites && !hasTrending) {
        if (feed.loading) {
          slivers.add(fill(const CircularProgressIndicator()));
        } else if (feed.error != null) {
          slivers.add(fill(errorView(feed)));
        } else {
          slivers.add(fill(
              message(Icons.gif_box_outlined, GifPicker.labelGifPickerEmpty)));
        }
      }
    } else {
      if (feed.loading) {
        slivers.add(fill(const CircularProgressIndicator()));
      } else if (feed.error != null) {
        slivers.add(fill(errorView(feed)));
      } else if (feed.results.isEmpty) {
        slivers.add(
            fill(message(Icons.search_off, GifPicker.labelGifPickerNoResults)));
      } else {
        slivers
            .add(grid(feed.results.length, (i) => resultTile(feed.results[i])));
      }
    }

    if (feed.loadingMore) {
      slivers.add(const SliverToBoxAdapter(
          child: Padding(
        padding: EdgeInsets.all(8),
        child: Center(
            child: SizedBox(
                width: 24, height: 24, child: CircularProgressIndicator())),
      )));
    }

    return Expanded(
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 400) {
            load(currentFeed, more: true);
          }
          return false;
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: slivers
              .map((s) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4), sliver: s))
              .toList(),
        ),
      ),
    );
  }

  Widget header(String text) {
    return SliverToBoxAdapter(child: tiamat.Text.labelLow(text));
  }

  Widget fill(Widget child) {
    return SliverFillRemaining(
        hasScrollBody: false, child: Center(child: child));
  }

  Widget message(IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: ColorScheme.of(context).secondary),
        const SizedBox(height: 8),
        tiamat.Text.labelLow(text),
      ],
    );
  }

  Widget errorView(_GifFeed feed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        message(Icons.error_outline, GifPicker.labelGifPickerError),
        TextButton(
            onPressed: () => load(feed),
            child: Text(GifPicker.promptGifPickerRetry)),
      ],
    );
  }

  Widget grid(int count, Widget Function(int index) builder) {
    return SliverMasonryGrid.extent(
      maxCrossAxisExtent: 300,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childCount: count,
      itemBuilder: (context, index) => builder(index),
    );
  }

  Widget favoriteTile(FavoriteGif result) {
    return AdaptiveContextMenu(
      items: [
        tiamat.ContextMenuItem(
          text: GifPicker.promptUnfavoriteGif,
          icon: Icons.heart_broken,
          onPressed: () {
            widget.onUnfavoriteGif?.call(result);
          },
        ),
      ],
      child: tile(
        aspectRatio: result.width / result.height,
        image: result.image,
        onTap: () => send(() => widget.favoritePicked?.call(result)),
      ),
    );
  }

  Widget resultTile(GifSearchResult result) {
    return tile(
      aspectRatio: result.x / result.y,
      image: NetworkImage(result.previewUrl.toString()),
      onTap: () => send(() => widget.gifPicked?.call(result)),
    );
  }

  Widget tile(
      {required double aspectRatio,
      required ImageProvider image,
      required void Function() onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: ColorScheme.of(context).surfaceContainerLowest,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Image(
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                image: image,
                errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: ColorScheme.of(context).secondary)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> send(Future<void>? Function() doSend) async {
    if (sending) return;

    setState(() {
      sending = true;
      sendFailed = false;
    });

    try {
      await doSend();
    } catch (e, s) {
      Log.onError(e, s, content: "Failed to send gif");
      sendFailed = true;
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
        });
      }
    }
  }
}
