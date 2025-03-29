import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/ui/molecules/image_picker.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:path/path.dart' as path;

class RoomEmojiPackSettingsView extends StatefulWidget {
  const RoomEmojiPackSettingsView(
      {required this.component, this.editable = true, super.key});
  final EmoticonComponent component;
  final bool editable;
  @override
  State<RoomEmojiPackSettingsView> createState() =>
      _RoomEmojiPackSettingsViewState();
}

class _RoomEmojiPackSettingsViewState extends State<RoomEmojiPackSettingsView> {
  late List<EmoticonPack> packs;

  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();

    sub = widget.component.onStateChanged.listen((_) => setState(() {
          packs = widget.component.ownedPacks;
        }));

    packs = widget.component.ownedPacks;
  }

  @override
  void dispose() {
    sub?.cancel;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: packs
          .map(
            (e) => Padding(
              padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
              child: ExpansionTile(
                collapsedBackgroundColor:
                    Theme.of(context).colorScheme.surfaceContainer,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                title: Row(
                  children: [
                    if (e.image != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                        child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Image(image: e.image!)),
                      ),
                    tiamat.Text.label(e.displayName),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                    child: EmoticonPackEditor(
                      pack: e,
                      editable: widget.editable,
                    ),
                  )
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class EmoticonPackEditor extends StatelessWidget {
  const EmoticonPackEditor(
      {required this.pack, this.editable = false, super.key});
  final EmoticonPack pack;
  final bool editable;

  String get createEmoticonDialogTitle => Intl.message("Create Emote",
      name: "createEmoticonDialogTitle",
      desc:
          "Title of a dialog that pops up when choosing to create a new emoticon");

  String get editEmoticonDialogTitle => Intl.message("Edit Emote",
      name: "editEmoticonDialogTitle",
      desc:
          "Title of a dialog that pops up when choosing to edit an existing emoticon");

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          children: pack.emotes
              .map((e) => Padding(
                    padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Material(
                        child: InkWell(
                          onTap: !editable
                              ? null
                              : () => AdaptiveDialog.show(context,
                                  title: editEmoticonDialogTitle,
                                  builder: (context) => EmoticonCreator(
                                        pack,
                                        initialEmoticon: e,
                                        onCreate:
                                            (name, usage, newImageData) async {
                                          await pack.updateEmoticon(
                                            previous: e,
                                            shortcode: name,
                                            usage: usage,
                                            data: newImageData,
                                          );
                                          return true;
                                        },
                                        onDelete: () async {
                                          await pack.deleteEmoticon(e);
                                        },
                                      ),
                                  dismissible: true),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Image(image: e.image!)),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    tiamat.Text.label(e.shortcode!)
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (e.isEmoji)
                                      Icon(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                          size: 20,
                                          Icons.emoji_emotions),
                                    if (e.isSticker)
                                      Icon(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                          Icons.sticky_note_2_rounded)
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        if (editable)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
              child: tiamat.CircleButton(
                icon: Icons.add,
                onPressed: () => AdaptiveDialog.show(context,
                    title: createEmoticonDialogTitle,
                    builder: (context) => EmoticonCreator(
                          pack,
                          onCreate: (name, usage, newImageData) async {
                            await pack.addEmoticon(
                                slug: name,
                                shortcode: name,
                                data: newImageData!,
                                usage: usage);

                            return true;
                          },
                        ),
                    dismissible: true),
              ),
            ),
          )
      ],
    );
  }
}

class EmoticonCreator extends StatefulWidget {
  const EmoticonCreator(this.pack,
      {this.initialEmoticon,
      this.createPack = false,
      this.onCreate,
      this.onDelete,
      super.key});

  final Emoticon? initialEmoticon;
  final EmoticonPack pack;
  final bool createPack;

  final Future<bool> Function(
      String name, EmoticonUsage usage, Uint8List? newImageData)? onCreate;

  final Future<void> Function()? onDelete;

  @override
  State<EmoticonCreator> createState() => _EmoticonCreatorState();
}

class _EmoticonCreatorState extends State<EmoticonCreator> {
  late EmoticonUsage usage;
  late ImageProvider? image;

  Uint8List? imageData;
  TextEditingController controller = TextEditingController();
  bool loading = false;

  String get promptEmoticonPackName => Intl.message("Pack name",
      name: "promptEmoticonPackName",
      desc: "Prompt for the input of the name of an emoticon pack");

  String get promptEmoteName => Intl.message("Emote name",
      name: "promptEmoteName",
      desc: "Prompt for the input of the name of an emoji");

  String get promptConfirmSaveEmoticon => Intl.message("Save!",
      name: "promptConfirmSaveEmoticon",
      desc:
          "Prompt to confirm the creation of an Emoticon Pack, Emoji, or Sticker");

  @override
  void initState() {
    super.initState();

    usage = widget.initialEmoticon?.usage ?? EmoticonUsage.all;
    controller.text = widget.initialEmoticon?.shortcode ?? "";
    image = widget.initialEmoticon?.image;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          opacity: loading ? 0.5 : 1,
          duration: Durations.short2,
          child: IgnorePointer(
            ignoring: loading,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 300, maxHeight: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: ImagePicker(
                            size: 50,
                            icon: Icons.add_a_photo,
                            withData: true,
                            currentImage: image,
                            onImageRead: (bytes, mimeType, filepath) {
                              imageData = bytes;
                              var name =
                                  path.basename(filepath).split('.').first;
                              if (controller.text.isEmpty &&
                                  !widget.createPack) {
                                controller.text = name;
                              }

                              image = Image.memory(bytes).image;
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 300),
                            child: tiamat.TextInput(
                              maxLines: 1,
                              placeholder: widget.createPack
                                  ? promptEmoticonPackName
                                  : promptEmoteName,
                              controller: controller,
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    SizedBox(
                      height: 40,
                      width: 40,
                      child: tiamat.DropdownSelector(
                        itemHeight: 40,
                        items: const [
                          EmoticonUsage.emoji,
                          EmoticonUsage.sticker,
                          EmoticonUsage.all,
                        ],
                        value: usage,
                        onItemSelected: (item) {
                          setState(() {
                            usage = item;
                          });
                        },
                        itemBuilder: (item) {
                          return Row(
                            children: [
                              Icon(switch (item) {
                                EmoticonUsage.sticker => Icons.sticky_note_2,
                                EmoticonUsage.emoji => Icons.emoji_emotions,
                                EmoticonUsage.all => Icons.star
                              }),
                              const SizedBox(
                                width: 8,
                              ),
                              tiamat.Text.label(switch (item) {
                                EmoticonUsage.sticker => "Sticker",
                                EmoticonUsage.emoji => "Emoji",
                                EmoticonUsage.all => "Emoji & Sticker",
                              })
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    SizedBox(
                      height: 48,
                      child: tiamat.Button(
                        text: promptConfirmSaveEmoticon,
                        onTap: () {
                          if (controller.text.isNotEmpty) {
                            setState(() {
                              loading = true;
                            });

                            widget.onCreate
                                ?.call(controller.text, usage, imageData)
                                .then((e) => Navigator.of(context).pop());
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    if (widget.initialEmoticon != null)
                      tiamat.Button.danger(
                        text: CommonStrings.promptDelete,
                        onTap: () {
                          if (controller.text.isNotEmpty) {
                            setState(() {
                              loading = true;
                            });

                            widget.onDelete
                                ?.call()
                                .then((e) => Navigator.of(context).pop());
                          }
                        },
                      )
                  ],
                ),
              ),
            ),
          ),
        ),
        if (loading) const Center(child: CircularProgressIndicator())
      ],
    );
  }
}
