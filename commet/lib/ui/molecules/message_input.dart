import 'dart:async';

import 'package:commet/client/components/gif/gif_component.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/ui/atoms/rich_text_field.dart';
import 'package:commet/ui/molecules/attachment_icon.dart';
import 'package:commet/ui/molecules/emoticon_picker.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/gif/gif_search_result.dart';
import 'package:commet/utils/autofill_utils.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:intl/intl.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:tiamat/config/config.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import '../../client/attachment.dart';
import '../../client/components/emoticon/emoticon.dart';

enum MessageInputSendResult { success, unhandled }

class MessageInput extends StatefulWidget {
  const MessageInput(
      {super.key,
      this.maxHeight = 200,
      this.onSendMessage,
      this.isRoomE2EE = false,
      this.onFocusChanged,
      this.readIndicator,
      this.relatedEventBody,
      this.relatedEventSenderColor,
      this.relatedEventSenderName,
      this.interactionType,
      this.focusKeyboard,
      this.setInputText,
      this.isProcessing = false,
      this.enabled = true,
      this.editLastMessage,
      this.hintText,
      this.attachments,
      this.addAttachment,
      this.onTextUpdated,
      this.removeAttachment,
      this.typingUsernames,
      this.availibleEmoticons,
      this.availibleStickers,
      this.gifComponent,
      this.onReadReceiptsClicked,
      this.sendGif,
      this.sendSticker,
      this.processAutofill,
      this.cancelReply});
  final double maxHeight;
  final double size = 48;
  final bool isRoomE2EE;
  final MessageInputSendResult Function(String message)? onSendMessage;
  final Widget? readIndicator;
  final String? relatedEventBody;
  final String? relatedEventSenderName;
  final String? hintText;
  final Color? relatedEventSenderColor;
  final List<PendingFileAttachment>? attachments;
  final EventInteractionType? interactionType;
  final Stream<void>? focusKeyboard;
  final Stream<String>? setInputText;
  final bool isProcessing;
  final bool enabled;
  final List<String>? typingUsernames;
  final List<EmoticonPack>? availibleEmoticons;
  final List<EmoticonPack>? availibleStickers;
  final GifComponent? gifComponent;
  final void Function()? onReadReceiptsClicked;
  final void Function(Emoticon sticker)? sendSticker;
  final Future<void> Function(GifSearchResult gif)? sendGif;
  final void Function(bool focused)? onFocusChanged;
  final Function(String currentText)? onTextUpdated;
  final void Function()? cancelReply;
  final void Function()? editLastMessage;
  final void Function(PendingFileAttachment attachment)? addAttachment;
  final void Function(PendingFileAttachment attachment)? removeAttachment;
  final List<AutofillSearchResult> Function(String text)? processAutofill;

  @override
  State<MessageInput> createState() => MessageInputState();
}

class MessageInputState extends State<MessageInput> {
  late FocusNode textFocus;
  late TextEditingController controller;
  late JustTheController emojiOverlayController = JustTheController();
  StreamSubscription? keyboardFocusSubscription;
  StreamSubscription? setInputTextSubscription;
  OverlayEntry? entry;
  final layerLink = LayerLink();
  bool showEmotePicker = false;
  bool hasEmotePickerOpened = false;
  List<AutofillSearchResult>? autoFillResults;
  int? autoFillSelection;
  (int, int)? autoFillRange;
  ScrollController autofillScrollController = ScrollController();

  String typingUsers(int howMany, String user1, String user2, String user3) =>
      Intl.plural(howMany,
          one: "$user1 is typing...",
          two: "$user1 and $user2 are typing...",
          few: "$user1, $user2, and $user3 are typing...",
          other: "Several people are typing...",
          desc: "Text to display which users are currently typing",
          name: "typingUsers",
          args: [howMany, user1, user2, user3]);

  void unfocus() {
    textFocus.unfocus();
  }

  void onKeyboardFocusRequested() {
    textFocus.requestFocus();
  }

  void onSetInputText(String newText) {
    controller.text = newText;
    controller.selection =
        TextSelection(baseOffset: newText.length, extentOffset: newText.length);
  }

  @override
  void dispose() {
    keyboardFocusSubscription?.cancel();
    setInputTextSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    controller = TextEditingController();
    keyboardFocusSubscription =
        widget.focusKeyboard?.listen((_) => onKeyboardFocusRequested());

    setInputTextSubscription = widget.setInputText?.listen(onSetInputText);

    controller.addListener(onTextfieldUpdated);

    textFocus = FocusNode(onKey: onKey);

    super.initState();
  }

  String? lastSearchText;
  void onTextfieldUpdated() {
    widget.onTextUpdated?.call(controller.text);
    var range = getAutofillTextRange();

    if (range.$1 == -1 || range.$2 == -1) {
      return;
    }

    var text = controller.text.substring(range.$1, range.$2);

    if (text == "") {
      setState(() {
        autoFillResults = null;
        autoFillSelection = null;
        autoFillRange = null;
      });
    }

    if (text == lastSearchText) {
      return;
    }

    var result = widget.processAutofill?.call(text);
    autoFillRange = range;

    setState(() {
      autoFillResults = result;
      autoFillSelection = null;
      updateAutofillScroll();
    });
  }

  (int, int) getAutofillTextRange() {
    var cursor = controller.selection.base.offset;
    if (cursor >= controller.text.length) {
      cursor = controller.text.length - 1;
    }

    if (controller.text == "") {
      return (0, 0);
    }

    int start = cursor;
    int end = controller.text.length;

    for (int i = cursor - 1; i >= 0; i--) {
      var char = controller.text[i];
      if (char == ' ') {
        if (i == controller.text.length) {
          start = controller.text.length - 1;
        } else {
          start = i + 1;
        }

        break;
      }

      if (i <= 0) {
        start = 0;
      }
    }

    for (var i = start + 1; i < controller.text.length; i++) {
      var char = controller.text[i];
      if (char == ' ') {
        end = i;
        break;
      }
    }

    return (start, end);
  }

  void sendMessage() {
    if (widget.attachments == null || widget.attachments!.isEmpty) {
      if (controller.text.isEmpty) return;
      if (controller.text.trim().isEmpty) return;
    }

    setState(() {
      showEmotePicker = false;
    });

    widget.onSendMessage?.call(controller.text.trim());
  }

  void toggleEmojiOverlay() {
    setState(() {
      showEmotePicker = !showEmotePicker;
      if (showEmotePicker) {
        hasEmotePickerOpened = true;
      }
    });
  }

  void updateAutofillScroll() {
    if (!autofillScrollController.hasClients) {
      return;
    }
    if (autoFillSelection == null) {
      autofillScrollController.jumpTo(0);
      return;
    }

    int totalChars = 0;
    int selectionChars = 0;
    for (int i = 0; i < autoFillResults!.length; i++) {
      totalChars += autoFillResults![i].result.length;

      if (autoFillSelection! > i) {
        selectionChars += autoFillResults![i].result.length;
      }
    }

    var maxOffset = autofillScrollController.position.maxScrollExtent;

    var amount = selectionChars.toDouble() / totalChars.toDouble();
    var offset = (maxOffset * amount) - 50;

    if (offset < 0) {
      offset = 0;
    }

    var distance = (offset - autofillScrollController.offset).abs();
    var maxDistance =
        autofillScrollController.position.viewportDimension * 0.25;

    if (distance > maxDistance) {
      autofillScrollController.animateTo(offset,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutExpo);
    }
  }

  KeyEventResult onKey(FocusNode node, RawKeyEvent event) {
    if (BuildConfig.MOBILE) return KeyEventResult.ignored;

    if (event.isKeyPressed(LogicalKeyboardKey.tab)) {
      if (autoFillResults == null || autoFillResults!.isEmpty) {
        autoFillSelection = null;
        return KeyEventResult.ignored;
      } else {
        if (autoFillSelection == null) {
          setState(() {
            autoFillSelection = 0;
            updateAutofillScroll();
          });
        } else {
          setState(() {
            autoFillSelection = (autoFillSelection! + 1);
            if (autoFillSelection! >= autoFillResults!.length) {
              autoFillSelection = 0;
            }

            updateAutofillScroll();
          });
        }

        return KeyEventResult.handled;
      }
    }

    if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
      if (autoFillSelection != null && autoFillRange != null) {
        applyAutoFill(autoFillResults![autoFillSelection!]);
        return KeyEventResult.handled;
      }

      if (event.isShiftPressed) {
        return KeyEventResult.ignored;
      }

      sendMessage();
      return KeyEventResult.handled;
    }

    if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
      doCancelInteraction();
      return KeyEventResult.handled;
    }

    if (event.isKeyPressed(LogicalKeyboardKey.arrowUp) &&
        controller.text.isEmpty) {
      widget.editLastMessage?.call();
    }

    return KeyEventResult.ignored;
  }

  void applyAutoFill(AutofillSearchResult result) {
    var replacement = result.slug;

    var checkWhitespaceAt = autoFillRange!.$2;

    if (checkWhitespaceAt < controller.text.length) {
      if (controller.text[checkWhitespaceAt] != " ") {
        replacement = "$replacement ";
      }
    } else {
      replacement = "$replacement ";
    }

    controller.text = controller.text
        .replaceRange(autoFillRange!.$1, autoFillRange!.$2, replacement);
    setState(() {
      autoFillSelection = null;
      autoFillResults = null;
      autoFillRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: TextFieldTapRegion(
        child: Opacity(
          opacity: widget.isProcessing ? 0.5 : 1,
          child: Tile(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                typingUsersWidget(),
                if (widget.interactionType != null) interactionText(),
                if (widget.attachments != null &&
                    widget.attachments!.isNotEmpty)
                  displayAttachments(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if (widget.enabled) addAttachmentButton(),
                          Flexible(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .extension<ExtraColors>()!
                                        .surfaceLow2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    textInput(context),
                                    if (widget.enabled) toggleEmojiButton(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (widget.enabled) sendMessageButton()
                        ]),
                  ),
                ),
                SizedBox(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(height: 30),
                        if (autoFillResults != null) autofillResultsList(),
                        if (autoFillResults == null)
                          const Expanded(child: SizedBox()),
                        if (widget.readIndicator != null) readReceipts()
                      ]),
                ),
                if (widget.availibleEmoticons != null &&
                    widget.availibleStickers != null)
                  AnimatedContainer(
                    curve: Curves.easeOutExpo,
                    duration: const Duration(milliseconds: 500),
                    height: showEmotePicker ? emotePickerHeight : 0,
                    child: buildEmojiPicker(),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  ClipRRect readReceipts() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onReadReceiptsClicked,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 2, 2),
            child: SizedBox(
              width: 150,
              child: widget.readIndicator!,
            ),
          ),
        ),
      ),
    );
  }

  Expanded autofillResultsList() {
    return Expanded(
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.center,
            colors: [
              Colors.purple,
              Colors.transparent,
            ],
            stops: [
              0.0,
              0.1,
            ],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstOut,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
          child: SizedBox(
            height: 30,
            child: ImplicitlyAnimatedList(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(0, 0, 300, 0),
              itemData: autoFillResults!,
              controller: autofillScrollController,
              shrinkWrap: true,
              itemBuilder: (context, data) {
                bool selected = false;

                if (autoFillSelection != null) {
                  selected = data == autoFillResults![autoFillSelection!];
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Material(
                    color: selected
                        ? Theme.of(context).extension<ExtraColors>()!.highlight
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () => applyAutoFill(data),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 1, 4, 1),
                        child: Row(
                          children: [
                            if (data is AutofillSearchResultEmoticon)
                              EmojiWidget(data.emoticon),
                            tiamat.Text.labelLow(
                              data.result,
                              color: selected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Padding sendMessageButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
      child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: tiamat.IconButton(
            icon: Icons.send,
            onPressed: sendMessage,
            size: 24,
          )),
    );
  }

  Padding toggleEmojiButton() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: tiamat.IconButton(
            icon: Icons.face,
            size: 24,
            onPressed: toggleEmojiOverlay,
          )),
    );
  }

  Expanded textInput(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 2, 4, 2),
        child: Stack(
          children: [
            RichTextField(
              controller: controller,
              focus: textFocus,
              readOnly: !widget.enabled,
              style: Theme.of(context).textTheme.bodyMedium!,
              contextMenuBuilder: contextMenuBuilder,
              hintText: widget.hintText,
            ),
          ],
        ),
      ),
    );
  }

  Padding addAttachmentButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: tiamat.IconButton(
          icon: Icons.add,
          size: 24,
          onPressed: addAttachment,
        ),
      ),
    );
  }

  double get emotePickerHeight =>
      (MediaQuery.of(context).size.height / (BuildConfig.MOBILE ? 2.5 : 3)) /
      preferences.appScale;

  Widget buildEmojiPicker() {
    return OverflowBox(
        minHeight: emotePickerHeight,
        maxHeight: emotePickerHeight,
        alignment: Alignment.topCenter,
        child: !hasEmotePickerOpened
            ? Container()
            : EmoticonPicker(
                emoji: widget.availibleEmoticons!,
                stickers: widget.availibleStickers ?? [],
                onEmojiPressed: insertEmoticon,
                packListAxis:
                    BuildConfig.DESKTOP ? Axis.vertical : Axis.horizontal,
                allowGifSearch: preferences.tenorGifSearchEnabled,
                gifComponent: widget.gifComponent,
                onStickerPressed: (emoticon) {
                  widget.sendSticker?.call(emoticon);
                  setState(() {
                    showEmotePicker = false;
                  });
                },
                onGifPressed: (gif) async {
                  await widget.sendGif?.call(gif);
                  setState(() {
                    showEmotePicker = false;
                  });
                }));
  }

  void addAttachment() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.any, withData: true);

    if (result != null) {
      for (var file in result.files) {
        var attachment = PendingFileAttachment(
            name: file.name,
            path: file.path,
            data: file.bytes,
            size: file.bytes?.length);
        widget.addAttachment?.call(attachment);
      }
    }
  }

  void doCancelInteraction() {
    if (widget.interactionType == EventInteractionType.edit) {
      controller.clear();
    }

    widget.cancelReply?.call();
  }

  void insertEmoticon(Emoticon emote) {
    var text = controller.text;
    var selection = controller.selection;
    int start = selection.start;
    int end = selection.end;
    String slug = emote.slug;

    if (start == -1 && end == -1) {
      if (!text.endsWith(" ")) text += " ";
      text += emote.slug;
      controller.text = text;
      return;
    }

    //Add whitespace where necessary
    if (emote.slug.startsWith(":") || emote.slug.endsWith(":")) {
      if (start > 0) {
        var startChar = text.characters.elementAt(start - 1);
        if (startChar != " ") slug = " $slug";
      }

      if (end < text.length) {
        var endChar = text.characters.elementAt(end);
        if (endChar != " ") slug = "$slug ";
      } else {
        slug = "$slug ";
      }
    }

    controller.text = text.replaceRange(start, end, slug);
    var newOffset = start + slug.length;
    controller.selection =
        TextSelection(baseOffset: newOffset, extentOffset: newOffset);
  }

  Widget interactionText() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 0, 4),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: tiamat.IconButton(
                icon: Icons.cancel_outlined,
                size: 16,
                onPressed: doCancelInteraction,
              ),
            ),
            Icon(widget.interactionType == EventInteractionType.reply
                ? Icons.keyboard_arrow_right_rounded
                : widget.interactionType == EventInteractionType.edit
                    ? Icons.edit
                    : null),
            tiamat.Text.name(
              widget.relatedEventSenderName!,
              color: widget.relatedEventSenderColor,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                child: tiamat.Text(
                  widget.relatedEventBody ?? "Unknown",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget displayAttachments() {
    return SizedBox(
      child: Row(
        children: widget.attachments!.map((e) {
          return Padding(
            padding: const EdgeInsets.all(2.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: GestureDetector(
                onTap: () {},
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: AttachmentIcon(
                    e,
                    removeAttachment: () => widget.removeAttachment?.call(e),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget contextMenuBuilder(
      BuildContext context, EditableTextState editableTextState) {
    return AdaptiveTextSelectionToolbar.editable(
      anchors: editableTextState.contextMenuAnchors,
      clipboardStatus: ClipboardStatus.pasteable,
      // to apply the normal behavior when click on copy (copy in clipboard close toolbar)
      // use an empty function `() {}` to hide this option from the toolbar
      onCopy: () =>
          editableTextState.copySelection(SelectionChangedCause.toolbar),
      // to apply the normal behavior when click on cut
      onCut: () =>
          editableTextState.cutSelection(SelectionChangedCause.toolbar),
      onPaste: () async {
        var clipboard = await Clipboard.getData("text/plain");

        if (clipboard != null) {
          return editableTextState.pasteText(SelectionChangedCause.toolbar);
        }

        editableTextState.hideToolbar();

        if (BuildConfig.DESKTOP) {
          var image = await Pasteboard.image;
          if (image != null) {
            widget.addAttachment
                ?.call(PendingFileAttachment(data: image, size: image.length));
          }
        }
      },
      // to apply the normal behavior when click on select all
      onSelectAll: () =>
          editableTextState.selectAll(SelectionChangedCause.toolbar),
      onLiveTextInput: null,
    );
  }

  Widget typingUsersWidget() {
    String text = getTypingText();

    return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
          child: tiamat.Text.labelLow(text),
        ));
  }

  String getTypingText() {
    if (widget.typingUsernames?.isEmpty == true) return "";

    String user1 = widget.typingUsernames![0];
    String user2 =
        widget.typingUsernames!.length >= 2 ? widget.typingUsernames![1] : "";
    String user3 =
        widget.typingUsernames!.length >= 3 ? widget.typingUsernames![2] : "";
    return typingUsers(widget.typingUsernames!.length, user1, user2, user3);
  }
}
