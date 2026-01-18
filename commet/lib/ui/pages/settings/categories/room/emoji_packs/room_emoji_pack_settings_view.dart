import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/ui/molecules/image_picker.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/settings/categories/room/emoji_packs/bulk_import_view.dart';
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
  bool canCreatePack = false;

  String get promptImportPack => Intl.message("Import pack",
      name: "promptImportPack",
      desc: "Prompt to import a set of emoticons from an existing pack");

  @override
  void initState() {
    super.initState();

    sub = widget.component.onStateChanged.listen((_) => updateState());

    updateState();
  }

  void updateState() {
    setState(() {
      packs = widget.component.ownedPacks;
      canCreatePack = widget.component.canCreatePack;
    });
  }

  @override
  void dispose() {
    sub?.cancel;
    super.dispose();
  }

  void promptBulkImport() async {
    await AdaptiveDialog.show(
      context,
      title: promptImportPack,
      builder: (context) {
        return EmoticonBulkImportDialog(
          importPack: (name, avatarIndex, names, imageDatas) {
            widget.component
                .importEmoticonPack(name, avatarIndex, names, imageDatas);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          children: packs
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                  child: ExpansionTile(
                    collapsedBackgroundColor:
                        Theme.of(context).colorScheme.surfaceContainer,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainer,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
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
                        Row(
                          children: [
                            Row(
                              children: [
                                if (widget.editable)
                                  tiamat.IconButton(
                                      size: 20,
                                      icon: Icons.edit,
                                      onPressed: () => AdaptiveDialog.show(
                                          context,
                                          builder: (context) => EmoticonCreator(
                                                pack: e,
                                                createPack: true,
                                                onCreate: (name, usage,
                                                    newImageData) async {
                                                  await e.updatePack(
                                                    name: name,
                                                    usage: usage,
                                                    imageData: newImageData,
                                                  );
                                                  return true;
                                                },
                                                onDelete: () {
                                                  return widget.component
                                                      .deleteEmoticonPack(e);
                                                },
                                              ))),
                                if (e.isEmojiPack)
                                  Icon(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                      size: 20,
                                      Icons.emoji_emotions),
                                if (e.isStickerPack)
                                  Icon(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                      Icons.sticky_note_2_rounded),
                                tiamat.IconToggle(
                                  icon: Icons.favorite,
                                  size: 17,
                                  state: e.isGloballyAvailable,
                                  onPressed: (newState) async {
                                    await e.markAsGlobal(newState);
                                    updateState();
                                  },
                                ),
                              ],
                            ),
                          ],
                        )
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
        ),
        if (canCreatePack)
          Align(
            alignment: Alignment.topRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                tiamat.CircleButton(
                    icon: Icons.auto_awesome_motion,
                    onPressed: promptBulkImport),
                const SizedBox(
                  width: 10,
                ),
                tiamat.CircleButton(
                    icon: Icons.add,
                    onPressed: () => AdaptiveDialog.show(context,
                        builder: (context) => EmoticonCreator(
                              createPack: true,
                              creatingNew: true,
                              onCreate: (name, usage, newImageData) async {
                                await widget.component
                                    .createEmoticonPack(name, newImageData);

                                return true;
                              },
                            ))),
              ],
            ),
          )
      ],
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
                                        pack: pack,
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
                                          Icons.sticky_note_2_rounded),
                                    if (e.usage == EmoticonUsage.inherit)
                                      Icon(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                          Icons.arrow_downward)
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
                          pack: pack,
                          creatingNew: true,
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
  const EmoticonCreator(
      {this.initialEmoticon,
      this.pack,
      this.createPack = false,
      this.onCreate,
      this.onDelete,
      this.creatingNew = false,
      super.key});

  final Emoticon? initialEmoticon;
  final EmoticonPack? pack;
  final bool createPack;
  final bool creatingNew;

  final Future<bool> Function(
      String name, EmoticonUsage usage, Uint8List? newImageData)? onCreate;

  final Future<void> Function()? onDelete;

  @override
  State<EmoticonCreator> createState() => _EmoticonCreatorState();
}

class _EmoticonCreatorState extends State<EmoticonCreator> {
  late EmoticonUsage usage;
  ImageProvider? image;

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

    if (widget.createPack) {
      if (widget.pack != null) {
        usage = widget.pack!.usage;
        controller.text = widget.pack!.displayName;
        image = widget.pack!.image;
      } else {
        usage = EmoticonUsage.all;
      }
    } else {
      if (widget.initialEmoticon != null) {
        usage = widget.initialEmoticon!.usage;
      } else {
        usage = EmoticonUsage.inherit;
      }
      controller.text = widget.initialEmoticon?.shortcode ?? "";
      image = widget.initialEmoticon?.image;
    }
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
                        child: ImagePickerButton(
                          size: 50,
                          icon: Icons.add_a_photo,
                          withData: true,
                          currentImage: image,
                          onImageRead: (bytes, mimeType, filepath) {
                            imageData = bytes;
                            var name = path.basename(filepath).split('.').first;
                            if (controller.text.isEmpty && !widget.createPack) {
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
                      items: [
                        EmoticonUsage.emoji,
                        EmoticonUsage.sticker,
                        EmoticonUsage.all,
                        if (!widget.createPack) EmoticonUsage.inherit,
                      ],
                      value: usage,
                      onItemSelected: (item) {
                        setState(() {
                          usage = item!;
                        });
                      },
                      itemBuilder: (item) {
                        return Row(
                          children: [
                            Icon(switch (item) {
                              EmoticonUsage.sticker => Icons.sticky_note_2,
                              EmoticonUsage.emoji => Icons.emoji_emotions,
                              EmoticonUsage.inherit => Icons.arrow_downward,
                              EmoticonUsage.all => Icons.star
                            }),
                            const SizedBox(
                              width: 8,
                            ),
                            tiamat.Text.label(switch (item) {
                              EmoticonUsage.sticker => "Sticker",
                              EmoticonUsage.emoji => "Emoji",
                              EmoticonUsage.inherit => "Follow Pack Settings",
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
                      onTap: () async {
                        if (controller.text.isNotEmpty) {
                          setState(() {
                            loading = true;
                          });

                          await widget.onCreate
                              ?.call(controller.text, usage, imageData);

                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  if (!widget.creatingNew)
                    tiamat.Button.danger(
                      text: CommonStrings.promptDelete,
                      onTap: () async {
                        final confirm =
                            await AdaptiveDialog.confirmation(context);

                        if (confirm == true) {
                          setState(() {
                            loading = true;
                          });

                          await widget.onDelete?.call();

                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                    )
                ],
              ),
            ),
          ),
        ),
        if (loading) const Center(child: CircularProgressIndicator())
      ],
    );
  }
}
