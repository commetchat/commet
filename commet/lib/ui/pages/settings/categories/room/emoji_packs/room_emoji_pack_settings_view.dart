import 'dart:async';
import 'dart:typed_data';

import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/ui/molecules/editable_label.dart';
import 'package:commet/ui/molecules/image_picker.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/settings/categories/room/emoji_packs/bulk_import_view.dart';
import 'package:commet/utils/common_animation.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/atoms/circle_button.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:path/path.dart' as path;

class RoomEmojiPackSettingsView extends StatefulWidget {
  final List<EmoticonPack> packs;
  final Stream<int>? onPackCreated;
  final Future<void> Function(String name, Uint8List? avatarData)?
      createNewPack;
  final Future<void> Function(EmoticonPack pack)? deletePack;
  final Future<void> Function(EmoticonPack pack, Emoticon emoticon)?
      deleteEmoticon;

  final Future<void> Function(
      EmoticonPack pack, Emoticon emoticon, String name)? renameEmoticon;

  final Function(String name, int avatarIndex, List<String> names,
      List<Uint8List> imageDatas)? importPack;

  final bool editable;
  final bool canCreatePack;
  final bool defaultExpanded;
  final bool showBulkImport;
  const RoomEmojiPackSettingsView(this.packs,
      {this.createNewPack,
      super.key,
      this.onPackCreated,
      this.deletePack,
      this.editable = true,
      this.canCreatePack = true,
      this.defaultExpanded = false,
      this.showBulkImport = true,
      this.importPack,
      this.renameEmoticon,
      this.deleteEmoticon});

  @override
  State<RoomEmojiPackSettingsView> createState() =>
      _RoomEmojiPackSettingsViewState();
}

class _RoomEmojiPackSettingsViewState extends State<RoomEmojiPackSettingsView> {
  int itemCount = 0;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  StreamSubscription? onItemAddedSubscription;
  String get promptCreateEmoticonPack => Intl.message("Create pack",
      name: "promptCreateEmoticonPack",
      desc: "Prompt to create a new emoticon pack, for emoji or stickers");

  String get promptImportPack => Intl.message("Import pack",
      name: "promptImportPack",
      desc: "Prompt to import a set of emoticons from an existing pack");

  @override
  void initState() {
    itemCount = widget.packs.length;
    onItemAddedSubscription = widget.onPackCreated?.listen(onPackAdded);
    super.initState();
  }

  @override
  void dispose() {
    onItemAddedSubscription?.cancel();
    super.dispose();
  }

  void onPackAdded(int index) {
    setState(() {
      _listKey.currentState?.insertItem(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedList(
          initialItemCount: itemCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          key: _listKey,
          itemBuilder: (context, index, animation) {
            return SizeTransition(
              sizeFactor: CommonAnimations.easeOut(animation),
              child: EmojiPackEditor(
                widget.packs[index],
                deletePack: () => deletePack(index),
                deleteEmoticon: (emoticon) => deleteEmoticon(index, emoticon),
                editable: widget.editable,
                initiallyExpanded: widget.defaultExpanded,
                renameEmoticon: (emoticon, name) =>
                    renameEmoticon(index, emoticon, name),
              ),
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.editable &&
                widget.canCreatePack &&
                widget.showBulkImport)
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: CircleButton(
                    radius: 20,
                    icon: Icons.auto_awesome_motion,
                    onPressed: promptBulkImport,
                  ),
                ),
              ),
            if (widget.editable && widget.canCreatePack)
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: CircleButton(
                    radius: 20,
                    icon: Icons.add,
                    onPressed: promptNewPack,
                  ),
                ),
              ),
          ],
        )
      ],
    );
  }

  void deletePack(int index) {
    var pack = widget.packs[index];
    widget.deletePack?.call(pack).then((_) {
      setState(() {
        itemCount--;
        _listKey.currentState?.removeItem(
            index,
            (context, animation) => SizeTransition(
                  sizeFactor: CommonAnimations.easeOut(animation),
                  child: EmojiPackEditor(
                    pack,
                  ),
                ));
      });
    });
  }

  Future<void> deleteEmoticon(int index, Emoticon emoticon) async {
    var pack = widget.packs[index];
    await widget.deleteEmoticon?.call(pack, emoticon);
  }

  Future<void> renameEmoticon(int index, Emoticon emoticon, String name) async {
    var pack = widget.packs[index];
    await widget.renameEmoticon?.call(pack, emoticon, name);
  }

  void promptNewPack() async {
    await AdaptiveDialog.show(
      context,
      title: promptCreateEmoticonPack,
      builder: (context) {
        return EmoticonCreator(
          pack: true,
          create: widget.createNewPack,
        );
      },
    );
  }

  void promptBulkImport() async {
    await AdaptiveDialog.show(
      context,
      title: promptImportPack,
      builder: (context) {
        return EmoticonBulkImportDialog(
          importPack: (name, avatarIndex, names, imageDatas) {
            widget.importPack?.call(name, avatarIndex, names, imageDatas);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class EmojiPackEditor extends StatefulWidget {
  const EmojiPackEditor(this.pack,
      {super.key,
      this.deletePack,
      this.deleteEmoticon,
      this.renameEmoticon,
      this.initiallyExpanded = false,
      this.showDeleteButton = true,
      this.editable = false});
  final EmoticonPack pack;
  final Function()? deletePack;
  final bool editable;
  final bool initiallyExpanded;
  final bool showDeleteButton;
  final Future<void> Function(Emoticon)? deleteEmoticon;
  final Future<void> Function(Emoticon, String)? renameEmoticon;

  @override
  State<EmojiPackEditor> createState() => _EmojiPackEditorState();
}

class _EmojiPackEditorState extends State<EmojiPackEditor> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  StreamSubscription? onCreate;
  late int _itemCount;
  late bool isPackEmoji;
  late bool isPackSticker;
  late bool isGlobalPack;

  String promptConfirmDeleteEmoticonPack(packName) => Intl.message(
      "Are you sure you want to delete the **$packName** pack?",
      args: [packName],
      name: "promptConfirmDeleteEmoticonPack",
      desc:
          "Prompt to confirm deletion of an emoticon pack, supports markdown to emphasise the pack name");

  String get createEmoticonDialogTitle => Intl.message("Create Emote",
      name: "createEmoticonDialogTitle",
      desc:
          "Title of a dialog that pops up when choosing to create a new emoticon");

  @override
  void initState() {
    widget.pack.onEmoticonAdded.listen(onEmojiInsert);
    _itemCount = widget.pack.emotes.length;
    isPackEmoji = widget.pack.isEmojiPack;
    isPackSticker = widget.pack.isStickerPack;
    isGlobalPack = widget.pack.isGloballyAvailable;
    super.initState();
  }

  void onEmojiInsert(int index) {
    setState(() {
      _itemCount++;
      _listKey.currentState?.insertItem(index);
    });
  }

  void setIsEmojiPack(bool isEmoji) {
    //if (!(isEmoji || isPackSticker)) return;

    setState(() {
      isPackEmoji = isEmoji;
    });

    widget.pack.markAsEmoji(isEmoji);
  }

  void setIsStickerPack(bool isSticker) {
    //if (!(isSticker || isPackEmoji)) return;

    setState(() {
      isPackSticker = isSticker;
    });

    widget.pack.markAsSticker(isSticker);
  }

  void setIsGlobal(bool isGlobal) {
    setState(() {
      isGlobalPack = isGlobal;
    });

    widget.pack.markAsGlobal(isGlobal);
  }

  void deleteEmoji(int index) {
    var emoji = widget.pack.emotes[index];
    widget.deleteEmoticon?.call(emoji).then((value) {
      setState(() {
        _itemCount--;
        _listKey.currentState?.removeItem(
            index,
            (context, animation) => SizeTransition(
                  sizeFactor: CommonAnimations.easeOut(animation),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 2, 0, 2),
                    child: EmojiEditor(
                      emoji,
                      editable: widget.editable,
                    ),
                  ),
                ));
      });
    });
  }

  void renameEmoji(int index, String name) {
    var emoji = widget.pack.emotes[index];
    widget.renameEmoticon?.call(emoji, name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ExpansionTile(
            initiallyExpanded: widget.initiallyExpanded,
            backgroundColor:
                Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
            collapsedBackgroundColor:
                Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (widget.pack.image != null || widget.pack.icon != null)
                      SizedBox(
                          width: 30,
                          height: 30,
                          child: widget.pack.image != null
                              ? Image(
                                  image: widget.pack.image!,
                                  filterQuality: FilterQuality.medium,
                                )
                              : Icon(
                                  widget.pack.icon!,
                                )),
                    const SizedBox(
                      width: 10,
                    ),
                    tiamat.Text.labelEmphasised(widget.pack.displayName),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: tiamat.IconToggle(
                        icon: Icons.public,
                        size: 20,
                        state: isGlobalPack,
                        onPressed: (newState) => setIsGlobal(newState),
                      ),
                    ),
                    if (widget.editable)
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: tiamat.IconToggle(
                          icon: Icons.sticky_note_2_rounded,
                          size: 20,
                          state: isPackSticker,
                          onPressed: (newState) => setIsStickerPack(newState),
                        ),
                      ),
                    if (widget.editable)
                      const SizedBox(
                        width: 4,
                      ),
                    if (widget.editable)
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: tiamat.IconToggle(
                          size: 20,
                          icon: Icons.emoji_emotions,
                          state: isPackEmoji,
                          onPressed: (newState) => setIsEmojiPack(newState),
                        ),
                      )
                  ],
                ),
              ],
            ),
            children: [
              AnimatedList(
                shrinkWrap: true,
                key: _listKey,
                physics: const NeverScrollableScrollPhysics(),
                initialItemCount: _itemCount,
                itemBuilder: (context, index, animation) {
                  return SizeTransition(
                    sizeFactor: CommonAnimations.easeOut(animation),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 2, 9, 2),
                      child: index >= widget.pack.emotes.length
                          ? Container()
                          : EmojiEditor(widget.pack.emotes[index],
                              deleteEmoji: () => deleteEmoji(index),
                              editable: widget.editable,
                              setIsEmoji: (value) => widget.pack
                                  .markEmoticonAsEmoji(
                                      widget.pack.emotes[index], value),
                              setIsSticker: (value) => widget.pack
                                  .markEmoticonAsSticker(
                                      widget.pack.emotes[index], value),
                              renameEmoji: (name) => renameEmoji(index, name)),
                    ),
                  );
                },
              ),
              if (widget.editable)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.showDeleteButton)
                        tiamat.Button.danger(
                            text: CommonStrings.promptDelete,
                            onTap: () async {
                              var result = await AdaptiveDialog.confirmation(
                                  context,
                                  dangerous: true,
                                  prompt: promptConfirmDeleteEmoticonPack(
                                      widget.pack.displayName));

                              if (result == true) widget.deletePack?.call();
                            }),
                      //Just putting a widget here to make the circle button stay on the right
                      if (!widget.showDeleteButton) const SizedBox(),
                      CircleButton(
                        radius: 20,
                        icon: Icons.add,
                        onPressed: createEmoticon,
                      ),
                    ],
                  ),
                )
            ]),
      ),
    );
  }

  void createEmoticon() async {
    await AdaptiveDialog.show(context,
        builder: (context) => EmoticonCreator(
              emoji: true,
              create: (name, data) async {
                await widget.pack
                    .addEmoticon(slug: name, shortcode: name, data: data!);
              },
            ),
        title: createEmoticonDialogTitle);
  }
}

class EmojiEditor extends StatefulWidget {
  final Emoticon emoji;
  const EmojiEditor(this.emoji,
      {super.key,
      this.deleteEmoji,
      this.editable = false,
      this.renameEmoji,
      this.setIsEmoji,
      this.setIsSticker});
  final void Function()? deleteEmoji;
  final void Function(String)? renameEmoji;
  final bool editable;
  final void Function(bool)? setIsEmoji;
  final void Function(bool)? setIsSticker;

  @override
  State<EmojiEditor> createState() => _EmojiEditorState();
}

class _EmojiEditorState extends State<EmojiEditor> {
  late bool isSticker;
  late bool isEmoji;

  String promptConfirmDeleteEmoticon(emoticon) => Intl.message(
      "Are you sure you want to delete **$emoticon**?",
      args: [emoticon],
      name: "promptConfirmDeleteEmoticon",
      desc:
          "Prompt to confirm deletion of an emoticon pack, supports markdown to emphasise the emote name");

  String get promptRenameEmoticon => Intl.message("Rename emote",
      name: "promptRenameEmoticon",
      desc: "Tooltip for button to rename emoticon");

  @override
  void initState() {
    isSticker = widget.emoji.isMarkedSticker;
    isEmoji = widget.emoji.isMarkedEmoji;
    super.initState();
  }

  void setSticker(bool newValue) {
    setState(() {
      isSticker = newValue;
    });

    widget.setIsSticker?.call(newValue);
  }

  void setEmoji(bool newValue) {
    setState(() {
      isEmoji = newValue;
    });

    widget.setIsEmoji?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.editable)
              tiamat.IconButton(
                icon: Icons.remove_circle_outline,
                size: 20,
                onPressed: () async {
                  var result = await AdaptiveDialog.confirmation(context,
                      prompt:
                          promptConfirmDeleteEmoticon(widget.emoji.shortcode!),
                      dangerous: true);

                  if (result == true) {
                    widget.deleteEmoji?.call();
                  }
                },
              ),
            SizedBox(
              height: 50,
              width: 50,
              child: EmojiWidget(widget.emoji),
            ),
            const SizedBox(
              width: 10,
            ),
            widget.editable
                ? EditableLabel(
                    initialText: widget.emoji.shortcode!,
                    changeTooltip: promptRenameEmoticon,
                    onTextConfirmed: (newText) =>
                        widget.renameEmoji?.call(newText!),
                  )
                : tiamat.Text.label(widget.emoji.shortcode!),
          ],
        ),
        if (widget.editable)
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: tiamat.IconToggle(
                  icon: Icons.sticky_note_2_rounded,
                  size: 20,
                  state: isSticker,
                  onPressed: setSticker,
                ),
              ),
              const SizedBox(
                width: 4,
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: tiamat.IconToggle(
                  size: 20,
                  icon: Icons.emoji_emotions,
                  state: isEmoji,
                  onPressed: setEmoji,
                ),
              ),
              const SizedBox(width: 43)
            ],
          ),
      ],
    );
  }
}

class EmoticonCreator extends StatefulWidget {
  const EmoticonCreator(
      {super.key, this.create, this.emoji, this.pack, this.sticker});
  final bool? pack;
  final bool? sticker;
  final bool? emoji;
  final Future<void> Function(String name, Uint8List? data)? create;

  @override
  State<EmoticonCreator> createState() => _EmoticonCreatorState();
}

class _EmoticonCreatorState extends State<EmoticonCreator> {
  Uint8List? imageData;
  ImageProvider? pickedImage;
  TextEditingController controller = TextEditingController();
  bool loading = false;

  String get promptEmoticonPackName => Intl.message("Pack name",
      name: "promptEmoticonPackName",
      desc: "Prompt for the input of the name of an emoticon pack");

  String get promptEmojiName => Intl.message("Emoji name",
      name: "promptEmojiName",
      desc: "Prompt for the input of the name of an emoji");

  String get promptStickerName => Intl.message("Sticker name",
      name: "promptStickerName", desc: "Prompt for the input of a sticker");

  String get promptConfirmCreateEmoticon => Intl.message("Create!",
      name: "promptConfirmCreateEmoticon",
      desc:
          "Prompt to confirm the creation of an Emoticon Pack, Emoji, or Sticker");

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 50, height: 50, child: CircularProgressIndicator()),
        ],
      );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: ImagePicker(
                  size: 64,
                  icon: Icons.add_a_photo,
                  withData: true,
                  currentImage: pickedImage,
                  onImageRead: (bytes, mimeType, filepath) {
                    imageData = bytes;
                    var name = path.basename(filepath).split('.').first;
                    if (controller.text.isEmpty && !(widget.pack == true)) {
                      controller.text = name;
                    }

                    pickedImage = Image.memory(bytes).image;
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 300),
                    child: tiamat.TextInput(
                      placeholder: widget.pack == true
                          ? promptEmoticonPackName
                          : widget.emoji == true
                              ? promptEmojiName
                              : promptStickerName,
                      controller: controller,
                    ),
                  ),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: SizedBox(
              height: 48,
              child: tiamat.Button(
                text: promptConfirmCreateEmoticon,
                onTap: () {
                  if (controller.text.isNotEmpty) {
                    setState(() {
                      loading = true;
                    });

                    if (widget.create != null) {
                      widget.create!
                          .call(controller.text, imageData)
                          .then((value) {
                        Navigator.pop(context);
                      });
                    }
                  }
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
