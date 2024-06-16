import 'dart:typed_data';

import 'package:commet/main.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/debounce.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:signal_sticker_api/signal_sticker_api.dart';
import 'package:tiamat/atoms/panel.dart';

import 'package:path/path.dart' as p;
import 'package:tiamat/tiamat.dart' as tiamat;

class EmoticonBulkImportDialog extends StatefulWidget {
  const EmoticonBulkImportDialog({super.key, this.importPack});
  final Function(String name, int avatarIndex, List<String> names,
      List<Uint8List> imageDatas)? importPack;

  @override
  State<EmoticonBulkImportDialog> createState() =>
      _EmoticonBulkImportDialogState();
}

class _EmoticonBulkImportDialogState extends State<EmoticonBulkImportDialog> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _packNameEditor = TextEditingController();
  final TextEditingController _emotePrefixEditor = TextEditingController();
  final TextEditingController _overrideNameEditor = TextEditingController();
  Debouncer debouncer = Debouncer(delay: const Duration(milliseconds: 500));

  List<String>? names;
  List<Uint8List?>? datas;
  List<ImageProvider?>? images;

  int? avatarIndex;

  String? prefix;
  String? overrideName;
  bool loading = false;

  bool useAsEmoji = false;
  bool useAsSticker = true;

  @override
  void initState() {
    _controller.addListener(onTextChanged);
    _emotePrefixEditor.addListener(onPrefixChanged);
    _overrideNameEditor.addListener(onOverrideChanged);
    super.initState();
  }

  void onTextChanged() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        loading = true;
      });
      debouncer.run(fetchUrl);
    } else {
      debouncer.cancel();
      setState(() {
        loading = false;
        reset();
      });
    }
  }

  void onPrefixChanged() {
    setState(() {
      prefix = _emotePrefixEditor.text;
    });
  }

  void onOverrideChanged() {
    setState(() {
      overrideName = _overrideNameEditor.text;
    });
  }

  List<String> ensureNoConflictingNames(List<String> names) {
    for (var i = 0; i < names.length; i++) {
      var name = names[i];
      if (names.where((element) => element == name).length > 1) {
        names[i] = "${name}_$i";
      }
    }

    return names;
  }

  String getFinalName(int index) {
    String name = names![index];
    if (overrideName != null && overrideName!.isNotEmpty) {
      name = overrideName!;
    }

    if (prefix != null) {
      name = "$prefix$name";
    }

    if (overrideName != null && overrideName!.isNotEmpty) {
      name = "${name}_$index";
    }

    return name;
  }

  void reset() {
    setState(() {
      _packNameEditor.text = "";
      _overrideNameEditor.text = "";
      _emotePrefixEditor.text = "";
      avatarIndex = null;
      names = null;
      datas = null;
      images = null;
    });
  }

  Future<void> fetchUrl() async {
    var uri = Uri.parse(_controller.text);
    await UnicodeEmojis.loadShortcodeData();

    reset();

    if (["https", "http", "sgnl"].contains(uri.scheme)) {
      await loadSignalPack(uri);
    }
  }

  Future<void> loadSignalPack(Uri uri) async {
    var client = SignalStickerClient(
        host: preferences.proxyUrl, rootPath: "/proxy/signal", useHttps: false);
    var packInfo = client.getPackFromUri(uri);
    var pack = await client.getPack(packInfo!);
    _packNameEditor.text = pack!.name;

    names = ensureNoConflictingNames(pack.stickers
        .map((e) => e.emoji)
        .toList()
        .map((e) => UnicodeEmojis.findShortcode(e)!)
        .toList());
    datas = List.generate(names!.length, (index) => null);
    images = List.generate(names!.length, (index) => null);

    setState(() {
      loading = false;
    });

    var coverId = pack.cover;

    if (!pack.stickers.any((element) => element.id == pack.cover)) {
      coverId = pack.stickers.first.id;
    }

    for (var i = 0; i < pack.stickers.length; i++) {
      var sticker = pack.stickers[i];
      sticker.getData().then((value) {
        setState(() {
          var bytes = Uint8List.fromList(value!);
          datas![i] = bytes;
          images![i] = Image.memory(bytes).image;

          if (coverId == sticker.id) {
            avatarIndex = i;
          }
        });
      });
    }
  }

  Future<void> pickFolder() async {
    var files = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true, allowMultiple: true);

    setState(() {
      reset();
      datas = files!.files.map((e) => e.bytes!).toList();
      images = files.files.map((e) => Image.memory(e.bytes!).image).toList();
      names =
          files.files.map((e) => p.basenameWithoutExtension(e.name)).toList();
      avatarIndex = 0;
      _controller.text = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    bool loadingFinished = images?.any(
          (element) => element == null,
        ) ==
        false;
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(width: 800, height: 800),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: [
          sourceSelection(),
          if (loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (loading == false && names != null)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: MasonryGridView.extent(
                      itemCount: names!.length,
                      maxCrossAxisExtent: 200,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      itemBuilder: entryBuilder),
                ),
              ),
            ),
          if (loading == false && names != null) packEdit(),
          if (images != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: tiamat.Button(
                isLoading: !loadingFinished,
                text: "Import ${names!.length} Emoticons!",
                onTap: () {
                  if (canCreatePack()) {
                    var finalNames =
                        names!.mapIndexed((e, i) => getFinalName(i)).toList();
                    widget.importPack?.call(_packNameEditor.text, avatarIndex!,
                        finalNames, datas!.map((e) => e!).toList());
                  }
                },
              ),
            )
        ],
      ),
    );
  }

  bool canCreatePack() {
    return _packNameEditor.text.isNotEmpty;
  }

  Widget packEdit() {
    return Panel(
      mode: tiamat.TileType.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: avatarIndex != null && images?[avatarIndex!] != null
                  ? tiamat.Avatar(
                      image: images![avatarIndex!],
                      radius: 50,
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tiamat.TextInput(
                    controller: _packNameEditor,
                    label: "Pack Name",
                    maxLines: 1,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: tiamat.Text.labelLow("Optional:"),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: tiamat.TextInput(
                          controller: _emotePrefixEditor,
                          label: "Prefix",
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Flexible(
                        child: tiamat.TextInput(
                          controller: _overrideNameEditor,
                          label: "Override Name",
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sourceSelection() {
    return Panel(
        header: "Select pack source",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tiamat.TextInput(
              placeholder: "Enter URL",
              controller: _controller,
              maxLines: 1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                    child: tiamat.Text.labelLow(
                        "Supports: sgnl:// and signal.art")),
                Flexible(
                  child: tiamat.Text.labelLow(
                      "Request will be proxied via ${preferences.proxyUrl}"),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 100,
                    height: 10,
                    child: tiamat.Seperator(),
                  ),
                  tiamat.Text.labelLow(CommonStrings.labelOr),
                  const SizedBox(
                    width: 100,
                    height: 10,
                    child: tiamat.Seperator(),
                  ),
                ],
              ),
            ),
            tiamat.Button(
              text: "Select Files",
              onTap: pickFolder,
            ),
          ],
        ));
  }

  Widget entryBuilder(BuildContext context, int index) {
    var background = index % 2 == 0
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Theme.of(context).colorScheme.surfaceContainerHigh;

    var loading = images?[index] != null;

    return DecoratedBox(
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(5)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 150, minWidth: 150),
          child: loading
              ? Column(
                  children: [
                    Image(
                      filterQuality: FilterQuality.medium,
                      fit: BoxFit.fill,
                      image: images![index]!,
                    ),
                    tiamat.Text.tiny(getFinalName(index))
                  ],
                )
              : const SizedBox(
                  width: 15,
                  height: 15,
                  child: Center(child: CircularProgressIndicator())),
        ),
      ),
    );
  }
}
