import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:matrix/matrix.dart' as matrix;

import '../../../../utils/emoji/unicode_emoji.dart';
import '../../../../utils/image_utils.dart';
import '../../matrix_mxc_image_provider.dart';
import '../../matrix_timeline.dart';
import 'matrix_emoticon.dart';
import 'matrix_emoticon_pack.dart';

class MatrixEmoticonComponent implements EmoticonComponent {
  MatrixEmoticonHelper helper;
  MatrixClient client;

  @override
  late List<EmoticonPack> ownedPacks;

  final StreamController<int> _onOwnedPackAdded = StreamController.broadcast();

  @override
  Stream<int> get onOwnedPackAdded {
    print("getting onOwnedPack");
    return _onOwnedPackAdded.stream;
  }

  MatrixEmoticonComponent(this.helper, this.client) {
    var state = helper.getAllStates();
    ownedPacks = List.empty(growable: true);

    if (state.isEmpty) return;

    for (var key in state.keys) {
      var value = state[key]!;
      if (value['pack'] == null && value['images'] == null) continue;
      var pack = MatrixEmoticonPack(key, helper);
      ownedPacks.add(pack);
    }
  }

  @override
  Future<void> createEmoticonPack(String name, Uint8List? avatarData) async {
    var data = await helper.createEmoticonPack(name, avatarData);
    if (data != null) {
      var pack = MatrixEmoticonPack(data['key'], helper);
      print("Added pack!");
      ownedPacks.add(pack);
      _onOwnedPackAdded.add(ownedPacks.length - 1);
    }
  }

  @override
  Future<void> deleteEmoticonPack(EmoticonPack pack) async {
    (pack as MatrixEmoticonPack).helper.deleteEmotionPack(pack.identifier);
    ownedPacks.remove(pack);
  }

  @override
  List<EmoticonPack> globalPacks() {
    var matrixClient = client.getMatrixClient();

    if (!matrixClient.accountData.containsKey("im.ponies.emote_rooms"))
      return [];

    var rooms =
        matrixClient.accountData["im.ponies.emote_rooms"]!.content['rooms'];

    var packs = List<EmoticonPack>.empty(growable: true);

    for (var roomId in rooms.keys) {
      var room = client.getRoom(roomId);
      var space = client.getSpace(roomId);

      if (room == null && space == null) continue;

      var packKeys = rooms[roomId] as Map<String, dynamic>;

      for (var packKey in packKeys.keys) {
        List emoji = room != null
            ? room.roomEmoticons!.ownedPacks
            : space!.emoticons!.ownedPacks;

        var matchingPacks =
            emoji.where((element) => element.identifier == packKey);

        if (matchingPacks.isEmpty) continue;

        packs.add(matchingPacks.first);
      }
    }

    return packs;
  }
}

class MatrixRoomEmoticonComponent extends MatrixEmoticonComponent
    implements RoomEmoticonComponent {
  MatrixRoom room;
  MatrixRoomEmoticonComponent(super.helper, super.client, this.room);

  @override
  Future<TimelineEvent?> sendSticker(
      Emoticon sticker, TimelineEvent? inReplyTo) async {
    if (sticker is! MatrixEmoticon) return null;

    var image = await ImageUtils.imageProviderToImage(sticker.image);

    matrix.Event? replyingTo;

    if (inReplyTo != null) {
      replyingTo = await room.matrixRoom.getEventById(inReplyTo.eventId);
    }
    String? mimeType;
    if (sticker.image is MatrixMxcImage) {
      mimeType = (sticker.image as MatrixMxcImage).mimeType;
    }

    var content = {
      "body": sticker.shortcode!,
      "url": sticker.emojiUrl.toString(),
      "info": {
        "w": image.width,
        "h": image.height,
        if (mimeType != null) "mimetype": mimeType
      }
    };

    var id = await room.matrixRoom.sendEvent(content,
        type: matrix.EventTypes.Sticker, inReplyTo: replyingTo);

    if (id != null) {
      var event = await room.matrixRoom.getEventById(id);
      return (room.timeline! as MatrixTimeline).convertEvent(event!);
    }

    return null;
  }

  @override
  List<EmoticonPack> get availableEmoji =>
      _getAvailablePacks(includeUnicode: true);

  @override
  List<EmoticonPack> get availableStickers =>
      _getAvailablePacks(includeUnicode: false);

  @override
  List<EmoticonPack> get availablePacks {
    List<EmoticonPack> packs = List.from(ownedPacks, growable: true);

    for (var space in room.client.spaces
        .where((element) => element.containsRoom(room.identifier))) {
      packs.addAll(space.emoticons!.ownedPacks);
    }

    if (room.client.emoticons == null) return packs;

    packs.addAll(room.client.emoticons!
        .globalPacks()
        .where((element) => !packs.contains(element)));

    packs.addAll(room.client.emoticons!.ownedPacks
        .where((element) => !packs.contains(element)));

    return packs;
  }

  Map<String, Map<String, String>> getEmotePacksFlat(
      matrix.ImagePackUsage emoticon) {
    var packs = availablePacks.whereType<MatrixEmoticonPack>();

    var result = <String, Map<String, String>>{};

    for (var pack in packs) {
      var key = "${pack.displayName}-${pack.ownerId}";
      result[key] = <String, String>{};
      for (var emote in pack.emotes) {
        result[key]![emote.shortcode!] =
            (emote as MatrixEmoticon).emojiUrl.toString();
      }
    }

    return result;
  }

  List<EmoticonPack> _getAvailablePacks({bool includeUnicode = false}) {
    var result = List<EmoticonPack>.of(ownedPacks);

    for (var space in room.client.spaces
        .where((element) => element.containsRoom(room.identifier))) {
      result.addAll(space.emoticons!.ownedPacks);
    }

    for (var pack in room.client.emoticons!.globalPacks()) {
      if (!result.contains(pack)) {
        result.add(pack);
      }
    }

    result.addAll(room.client.emoticons!.ownedPacks);

    if (includeUnicode) result.addAll(UnicodeEmojis.packs!);

    return result;
  }
}
