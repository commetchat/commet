import 'dart:ui';

import 'package:commet/config/build_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import '../../utils/debounce.dart';
import '../../client/components/gif/gif_search_result.dart';

class GifPicker extends StatefulWidget {
  const GifPicker(
      {super.key,
      this.gifPicked,
      this.search,
      this.placeholderText = "Search Gif"});
  final Future<void> Function(GifSearchResult gif)? gifPicked;
  final Future<List<GifSearchResult>> Function(String query)? search;

  final String placeholderText;

  @override
  State<GifPicker> createState() => _GifPickerState();
}

class _GifPickerState extends State<GifPicker> {
  List<GifSearchResult>? searchResult;
  bool searching = false;
  bool sending = false;

  final TextEditingController _textController = TextEditingController();
  Debouncer debouce = Debouncer(delay: const Duration(milliseconds: 500));

  @override
  void initState() {
    _textController.addListener(onTextChanged);
    super.initState();
  }

  String prevText = "";
  void onTextChanged() {
    if (_textController.text == prevText) {
      return;
    }

    prevText = _textController.text;

    if (_textController.text.isNotEmpty) {
      setState(() {
        searching = true;
        searchResult = null;
      });
      debouce.run(() => doSearch(_textController.text));
    } else {
      debouce.cancel();
      setState(() {
        searching = false;
      });
    }
  }

  void doSearch(String query) {
    setState(() {
      searching = true;
    });

    widget.search?.call(query).then((value) {
      setState(() {
        searchResult = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
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
    ]);
  }

  Widget buildContent(BuildContext context) {
    if (BuildConfig.MOBILE) {
      return Column(children: [buildSearchBar(), buildSearch(context)]);
    } else {
      return Column(children: [buildSearch(context), buildSearchBar()]);
    }
  }

  Widget buildSearchBar() {
    return tiamat.Tile.low(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
            height: BuildConfig.DESKTOP ? 30 : null,
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                  icon: const Icon(Icons.search),
                  isDense: true,
                  border: InputBorder.none,
                  hintText: widget.placeholderText),
            )),
      ),
    );
  }

  Widget buildSearch(BuildContext context) {
    if (!searching) {
      return const Expanded(child: SizedBox());
    }

    if (searchResult == null)
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );

    return Expanded(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: MasonryGridView.extent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: searchResult!.length,
        itemBuilder: (context, index) {
          var result = searchResult!.elementAt(index);
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => sendGif(result),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: result.x / result.y,
                  child: SizedBox(
                    child: Image(
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                      image: NetworkImage(result.previewUrl.toString()),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ));
  }

  void sendGif(GifSearchResult gif) {
    setState(() {
      sending = true;
    });

    widget.gifPicked?.call(gif).then((value) => setState(() {
          sending = false;
        }));
  }
}
