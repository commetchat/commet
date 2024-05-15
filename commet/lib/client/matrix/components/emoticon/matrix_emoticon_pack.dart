import 'dart:typed_data';

import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_room_emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_space_emoticon_component.dart';
import 'package:commet/client/matrix/extensions/matrix_client_extensions.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/widgets.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:matrix/matrix.dart';

class MatrixEmoticonPack implements EmoticonPack {
  late final MatrixEmoticonComponent component;
  String stateKey;

  @override
  final NotifyingList<MatrixEmoticon> emotes =
      NotifyingList.empty(growable: true);

  late Map<String, Emoticon> shortcodeToEmoticon;

  @override
  late String displayName;

  @override
  ImageProvider? image;

  @override
  IconData? icon;

  MatrixEmoticonPack(
    this.component,
    this.stateKey,
    Map<String, dynamic> initialState,
  ) {
    updateFromState(initialState);
  }

  void updateFromState(Map<String, dynamic> initialState) {
    var info = initialState['pack'];
    displayName = info?['display_name'] ?? component.getDefaultDisplayName();
    shortcodeToEmoticon = <String, Emoticon>{};
    if (info?['avatar_url'] != null) {
      try {
        var uri = Uri.parse(info!['avatar_url']!);
        image = MatrixMxcImage(uri, component.client.getMatrixClient());
      } catch (_) {}
    }

    image ??= component.getDefaultImage();
    icon = component.getDefaultIcon();

    var images = initialState['images'] as Map<String, dynamic>?;
    if (images == null) return;

    bool isStickerPackCache = isStickerPack;
    bool isEmojiPackCache = isEmojiPack;

    emotes.removeWhere((element) => images.containsKey(element.key) == false);
    shortcodeToEmoticon.removeWhere((key, value) =>
        emotes.any((element) => element.shortcode == key) == false);

    for (var image in images.keys) {
      var url = images[image]['url'];
      if (url == null) {
        continue;
      }
      var uri = Uri.parse(url);

      var usages = images[image]['usage'] as List?;

      bool markedSticker = false;
      bool markedEmoji = false;
      if (usages != null) {
        markedSticker = usages.contains("sticker");
        markedEmoji = usages.contains("emoticon");
      }

      var existing =
          emotes.where((element) => element.key == image).firstOrNull;

      if (existing != null) {
        existing.markAsSticker(markedSticker);
        existing.markAsEmoji(markedEmoji);
        existing.markPackAsEmoji(isEmojiPackCache);
        existing.markPackAsSticker(isStickerPackCache);

        if (uri != existing.emojiUrl) {
          existing.emojiUrl = uri;
          existing.setImage(
              MatrixMxcImage(uri, component.client.getMatrixClient()));
        }
      } else {
        var emote = MatrixEmoticon(uri, component.client.getMatrixClient(),
            shortcode: image,
            isEmojiPack: isEmojiPackCache,
            isStickerPack: isStickerPackCache,
            isMarkedEmoji: markedEmoji,
            isMarkedSticker: markedSticker);
        emotes.add(emote);

        if (emote.shortcode != null) {
          shortcodeToEmoticon[emote.shortcode!] = emote;
        }
      }
    }
  }

  @override
  Future<void> addEmoticon(
      {required String slug,
      String? shortcode,
      required Uint8List data,
      String? mimeType,
      bool? isEmoji,
      bool? isSticker}) async {
    var result = await component.createEmoticon(identifier, shortcode!, data);
    if (result == null) return;

    var url = result['images'][shortcode]['url'];

    try {
      var uri = Uri.parse(url);
      var emote = MatrixEmoticon(uri, component.client.getMatrixClient(),
          shortcode: shortcode);
      emotes.add(emote);

      if (emote.shortcode != null) {
        shortcodeToEmoticon[emote.shortcode!] = emote;
      }
    } catch (_) {}
  }

  List? _getUsage() {
    var info =
        component.state.getState(identifier)['pack'] as Map<String, dynamic>?;
    if (info == null) return null;

    var usage = info.tryGet("usage") as List?;
    return usage;
  }

  @override
  String get attribution => "";

  @override
  Future<void> deleteEmoticon(Emoticon emoticon) async {
    await component.deleteEmoticon(identifier, emoticon.shortcode!);
    emotes.remove(emoticon);

    if (emoticon.shortcode != null) {
      shortcodeToEmoticon.remove(emoticon.shortcode);
    }
  }

  @override
  List<Emoticon> get emoji =>
      emotes.where((element) => element.isEmoji).toList();

  @override
  List<Emoticon> get stickers =>
      emotes.where((element) => element.isSticker).toList();

  @override
  String get identifier => stateKey;

  @override
  bool get isEmojiPack => _getUsage()?.contains("emoticon") ?? true;

  @override
  bool get isGloballyAvailable => component.isGloballyAvailable(identifier);

  @override
  bool get isStickerPack => _getUsage()?.contains("sticker") ?? true;

  @override
  Future<void> markAsGlobal(bool isGlobal) async {
    late Room room;
    if (component is MatrixRoomEmoticonComponent) {
      room = (component as MatrixRoomEmoticonComponent).room.matrixRoom;
    } else if (component is MatrixSpaceEmoticonComponent) {
      room = (component as MatrixSpaceEmoticonComponent).space.matrixRoom;
    } else {
      return;
    }

    if (isGlobal) {
      return room.client.addEmoticonRoomPack(room.id, identifier);
    } else {
      return room.client.removeEmoticonRoomPack(room.id, identifier);
    }
  }

  @override
  Future<void> markAsEmoji(bool isEmojiPack) async {
    await component.setPackUsages(identifier,
        [if (isEmojiPack) 'emoticon', if (isStickerPack) 'sticker']);

    for (var emote in emotes) {
      emote.markPackAsEmoji(isEmojiPack);
    }
  }

  @override
  Future<void> markAsSticker(bool isStickerPack) async {
    await component.setPackUsages(identifier,
        [if (isEmojiPack) 'emoticon', if (isStickerPack) 'sticker']);

    for (var emote in emotes) {
      emote.markPackAsSticker(isStickerPack);
    }
  }

  @override
  Future<void> markEmoticonAsEmoji(Emoticon emoticon, bool isEmoji) async {
    await component.setEmoticonUsages(identifier, emoticon.shortcode!,
        [if (isEmoji) 'emoticon', if (emoticon.isMarkedSticker) 'sticker']);

    (emoticon as MatrixEmoticon).markAsEmoji(isEmoji);
  }

  @override
  Future<void> markEmoticonAsSticker(Emoticon emoticon, bool isSticker) async {
    await component.setEmoticonUsages(identifier, emoticon.shortcode!,
        [if (emoticon.isMarkedEmoji) 'emoticon', if (isSticker) 'sticker']);

    (emoticon as MatrixEmoticon).markAsSticker(isSticker);
  }

  @override
  Stream<int> get onEmoticonAdded => emotes.onAdd;

  @override
  Future<void> renameEmoticon(Emoticon emoticon, String name) {
    return component.renameEmoticon(identifier, emoticon.shortcode!, name);
  }

  @override
  List<String> getShortcodes() {
    return emoji.map((e) => e.shortcode!).toList();
  }

  @override
  List<Emoticon> search(String searchText, [int limit = -1]) {
    var fuzzy = Fuzzy<Emoticon>(emoji,
        options: FuzzyOptions(threshold: 0.4, keys: [
          WeightedKey(
              name: "shortcode",
              getter: (obj) {
                return obj.shortcode ?? "";
              },
              weight: 1)
        ]));

    return fuzzy.search(searchText, limit).map((e) => e.item).toList();
  }

  @override
  Emoticon? getByShortcode(String shortcode) {
    return shortcodeToEmoticon[shortcode];
  }

  @override
  String get ownerId => component.ownerId;

  @override
  String get ownerDisplayName => component.ownerDisplayName;
}
