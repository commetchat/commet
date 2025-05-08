import 'dart:typed_data';

import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_room_emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_space_emoticon_component.dart';
import 'package:commet/client/matrix/extensions/matrix_client_extensions.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:matrix/matrix.dart';

class MatrixEmoticonPack implements EmoticonPack {
  late final MatrixEmoticonComponent component;
  String stateKey;

  @override
  List<MatrixEmoticon> get emotes {
    final images = state.tryGetMap<String, Map<String, dynamic>>("images");

    if (images == null) {
      return List.empty();
    }

    return images.entries.map((e) {
      final shortCode = e.key;
      final url = e.value.tryGet<String>("url");
      final usages = e.value.tryGetList<String>("usage");

      if (url == null) {
        throw UnimplementedError;
      }

      final usage = usagesArrayToUsage(usages);

      return MatrixEmoticon(Uri.parse(url), component.client.getMatrixClient(),
          packUsage: this.usage, shortcode: shortCode, usage: usage);
    }).toList();
  }

  late Map<String, Emoticon> shortcodeToEmoticon;

  late Map<String, dynamic> state;

  @override
  String get displayName {
    return state
            .tryGetMap<String, dynamic>("pack")
            ?.tryGet<String>("display_name") ??
        "Unnamed Pack";
  }

  @override
  ImageProvider? get image {
    final pack = state.tryGetMap<String, dynamic>("pack");

    final url = pack?.tryGet<String>("avatar_url");

    if (url != null) {
      return MatrixMxcImage(Uri.parse(url), component.client.getMatrixClient(),
          doFullres: true, fullResHeight: 64);
    }

    return null;
  }

  @override
  IconData? get icon {
    return component.getDefaultIcon();
  }

  MatrixEmoticonPack(this.component, this.stateKey, this.state);

  EmoticonUsage usagesArrayToUsage(List<String>? usages) {
    if ((usages?.contains("emoticon") == true) &&
        (usages?.contains("sticker") == false)) {
      return EmoticonUsage.emoji;
    }

    if ((usages?.contains("sticker") == true) &&
        (usages?.contains("emoticon") == false)) {
      return EmoticonUsage.sticker;
    }

    if ((usages?.contains("sticker") == true) &&
        (usages?.contains("emoticon") == true)) {
      return EmoticonUsage.all;
    }

    return EmoticonUsage.inherit;
  }

  @override
  Future<void> addEmoticon({
    required String slug,
    String? shortcode,
    required Uint8List data,
    String? mimeType,
    EmoticonUsage? usage,
  }) async {
    await component.createEmoticon(identifier, shortcode!, data);
  }

  @override
  Future<void> updateEmoticon(
      {String? slug,
      String? shortcode,
      Uint8List? data,
      String? mimeType,
      EmoticonUsage? usage,
      required Emoticon previous}) async {
    await component.updateEmoticon(identifier, shortcode!,
        data: data, usage: usage, previous: previous);
  }

  @override
  String get attribution => "";

  @override
  Future<void> deleteEmoticon(Emoticon emoticon) async {
    await component.deleteEmoticon(identifier, emoticon.shortcode!);
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

  List<String>? _emoticonUsageToArray(EmoticonUsage usage) {
    final usages = switch (usage) {
      EmoticonUsage.sticker => ["sticker"],
      EmoticonUsage.emoji => ["emoticon"],
      EmoticonUsage.all => ["sticker", "emoticon"],
      EmoticonUsage.inherit => null,
    };

    return usages;
  }

  @override
  Future<void> setPackUsage(EmoticonUsage usage) {
    final usages = _emoticonUsageToArray(usage);
    return component.setPackUsages(identifier, usages);
  }

  @override
  Future<void> updatePack(
      {EmoticonUsage? usage, String? name, Uint8List? imageData}) {
    return component.updatePack(identifier,
        usage: usage, name: name, imageData: imageData);
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

  @override
  bool operator ==(Object other) {
    if (other is! MatrixEmoticonPack) return false;
    if (other.component != component) return false;

    return (other.stateKey == stateKey &&
        other.component.state.id == component.state.id);
  }

  @override
  int get hashCode => stateKey.hashCode;

  @override
  EmoticonUsage get usage {
    final pack = state.tryGetMap<String, dynamic>("pack");
    var usages = pack?.tryGetList<String>("usage");
    var usage = usagesArrayToUsage(usages);
    if (usage == EmoticonUsage.inherit) {
      return EmoticonUsage.all;
    } else {
      return usage;
    }
  }

  @override
  bool get isEmojiPack =>
      [EmoticonUsage.emoji, EmoticonUsage.all].contains(usage);

  @override
  bool get isStickerPack =>
      [EmoticonUsage.sticker, EmoticonUsage.all].contains(usage);

  @override
  bool get isGloballyAvailable {
    late Room room;
    if (component is MatrixRoomEmoticonComponent) {
      room = (component as MatrixRoomEmoticonComponent).room.matrixRoom;
    } else if (component is MatrixSpaceEmoticonComponent) {
      room = (component as MatrixSpaceEmoticonComponent).space.matrixRoom;
    } else {
      return false;
    }

    final data = room
        .client.accountData[MatrixEmoticonComponent.globalEmoteRoomsStateKey];
    if (data == null) {
      return false;
    }

    final rooms = data.content.tryGetMap<String, dynamic>("rooms");

    if (rooms == null) {
      return false;
    }

    final roomData = rooms.tryGetMap<String, dynamic>(room.id);

    return roomData?.containsKey(identifier) ?? false;
  }
}
