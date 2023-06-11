import 'dart:async';
import 'dart:typed_data';

import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/ui/molecules/editable_label.dart';
import 'package:commet/ui/molecules/image_picker.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/common_animation.dart';
import 'package:commet/utils/emoji/emoticon.dart';
import 'package:commet/utils/emoji/emoji_pack.dart';
import 'package:flutter/material.dart';
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

  final bool editable;

  const RoomEmojiPackSettingsView(this.packs,
      {this.createNewPack,
      super.key,
      this.onPackCreated,
      this.deletePack,
      this.editable = true,
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
          key: _listKey,
          itemBuilder: (context, index, animation) {
            return SizeTransition(
              sizeFactor: CommonAnimations.easeOut(animation),
              child: EmojiPackEditor(
                widget.packs[index],
                deletePack: () => deletePack(index),
                deleteEmoticon: (emoticon) => deleteEmoticon(index, emoticon),
                editable: widget.editable,
                renameEmoticon: (emoticon, name) =>
                    renameEmoticon(index, emoticon, name),
              ),
            );
          },
        ),
        if (widget.editable)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: CircleButton(
                radius: 20,
                icon: Icons.add,
                onPressed: promptNewPack,
              ),
            ),
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
      title: "Create pack",
      builder: (context) {
        return EmoticonCreator(
          pack: true,
          create: widget.createNewPack,
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
      this.editable = false});
  final EmoticonPack pack;
  final Function()? deletePack;
  final bool editable;
  final Future<void> Function(Emoticon)? deleteEmoticon;
  final Future<void> Function(Emoticon, String)? renameEmoticon;

  @override
  State<EmojiPackEditor> createState() => _EmojiPackEditorState();
}

class _EmojiPackEditorState extends State<EmojiPackEditor> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  StreamSubscription? onCreate;
  late int _itemCount;

  @override
  void initState() {
    widget.pack.onEmoticonAdded.listen(onEmojiInsert);
    _itemCount = widget.pack.emotes.length;
    super.initState();
  }

  void onEmojiInsert(int index) {
    setState(() {
      _itemCount++;
      _listKey.currentState?.insertItem(index);
    });
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
            initiallyExpanded: false,
            backgroundColor:
                Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
            collapsedBackgroundColor:
                Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
            title: Row(
              children: [
                if (widget.pack.image != null)
                  SizedBox(
                      width: 30,
                      height: 30,
                      child: Image(
                        image: widget.pack.image!,
                        filterQuality: FilterQuality.medium,
                      )),
                const SizedBox(
                  width: 10,
                ),
                tiamat.Text.labelEmphasised(widget.pack.displayName),
              ],
            ),
            children: [
              AnimatedList(
                shrinkWrap: true,
                key: _listKey,
                initialItemCount: _itemCount,
                itemBuilder: (context, index, animation) {
                  return SizeTransition(
                    sizeFactor: CommonAnimations.easeOut(animation),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 2, 0, 2),
                      child: EmojiEditor(widget.pack.emotes[index],
                          deleteEmoji: () => deleteEmoji(index),
                          editable: widget.editable,
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
                      tiamat.Button.danger(
                          text: "Delete",
                          onTap: () async {
                            var result = await AdaptiveDialog.confirmation(
                                context,
                                dangerous: true,
                                prompt: T.current.promptEmoticonPackDelete(
                                    widget.pack.displayName));

                            if (result == true) widget.deletePack?.call();
                          }),
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
        title: "Create emoji");
  }
}

class EmojiEditor extends StatefulWidget {
  final Emoticon emoji;
  const EmojiEditor(this.emoji,
      {super.key, this.deleteEmoji, this.editable = false, this.renameEmoji});
  final void Function()? deleteEmoji;
  final void Function(String)? renameEmoji;
  final bool editable;

  @override
  State<EmojiEditor> createState() => _EmojiEditorState();
}

class _EmojiEditorState extends State<EmojiEditor> {
  bool editMode = false;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                      T.current.promptEmoticonDelete(widget.emoji.shortcode!),
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
        Expanded(
            child: widget.editable
                ? EditableLabel(
                    initialText: widget.emoji.shortcode!,
                    changeTooltip: "Rename emoji",
                    onTextConfirmed: (newText) =>
                        widget.renameEmoji?.call(newText!),
                  )
                : tiamat.Text.label(widget.emoji.shortcode!))
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

  @override
  Widget build(BuildContext context) {
    if (loading)
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
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
                          ? "Pack name"
                          : widget.emoji == true
                              ? "Emoji name"
                              : "Sticker name",
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
                text: "Create!",
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