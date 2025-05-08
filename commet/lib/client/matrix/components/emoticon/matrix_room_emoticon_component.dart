import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_state_manager.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_space_emoticon_component.dart';
import 'package:commet/client/matrix/extensions/matrix_client_extensions.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_file_provider.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:commet/utils/image_utils.dart';
import 'package:commet/utils/mime.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixRoomEmoticonComponent extends MatrixEmoticonComponent
    implements RoomEmoticonComponent<MatrixClient, MatrixRoom> {
  @override
  MatrixRoom room;

  MatrixRoomEmoticonComponent(MatrixClient client, this.room)
      : super(client, MatrixEmoticonRoomStateManager(room.matrixRoom));

  @override
  List<EmoticonPack> get availableEmoji =>
      _getAvailablePacks(includeUnicode: true)
          .where((element) => element.emoji.isNotEmpty)
          .toList();

  @override
  List<EmoticonPack> get availableStickers =>
      _getAvailablePacks(includeUnicode: false)
          .where((element) => element.stickers.isNotEmpty)
          .toList();

  @override
  bool get canCreatePack => room.permissions.canEditRoomEmoticons;

  @override
  String get ownerId => room.identifier;

  @override
  String get ownerDisplayName => room.displayName;

  @override
  List<EmoticonPack> get availablePacks {
    List<EmoticonPack> packs = List.from(ownedPacks, growable: true);

    for (var space in room.client.spaces
        .where((element) => element.containsRoom(room.identifier))) {
      var component = space.getComponent<SpaceEmoticonComponent>();
      if (component == null) continue;
      packs.addAll(component.ownedPacks);
    }

    var component = room.client.getComponent<EmoticonComponent>();

    if (component == null) return packs;

    packs.addAll(
        component.globalPacks().where((element) => !packs.contains(element)));

    packs.addAll(
        component.ownedPacks.where((element) => !packs.contains(element)));

    return packs;
  }

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

    // Sometimes MatrixMxcImage doesnt have mimetype loaded, so we need to look it up manually
    if (mimeType == null) {
      var provider =
          MxcFileProvider(client.getMatrixClient(), sticker.emojiUrl);
      var data = await provider.getFileData();
      mimeType = Mime.lookupType("", data: data);
    }

    var extension = "";

    // element web wont render images if the body doesnt have an extension
    if (mimeType != null) {
      extension = ".${mimeType.split("/").last}";
    }

    var content = {
      "body": sticker.shortcode! + extension,
      "url": sticker.emojiUrl.toString(),
      if (preferences.stickerCompatibilityMode) "msgtype": "m.image",
      if (preferences.stickerCompatibilityMode)
        "chat.commet.type": "chat.commet.sticker",
      "info": {
        "w": image.width,
        "h": image.height,
        if (mimeType != null) "mimetype": mimeType
      }
    };

    var id = await room.matrixRoom.sendEvent(content,
        type: preferences.stickerCompatibilityMode
            ? matrix.EventTypes.Message
            : matrix.EventTypes.Sticker,
        inReplyTo: replyingTo);

    if (id != null) {
      var event = await room.matrixRoom.getEventById(id);
      return room.convertEvent(event!,
          timeline: (room.timeline as MatrixTimeline?)?.matrixTimeline);
    }

    return null;
  }

  List<EmoticonPack> _getAvailablePacks({bool includeUnicode = false}) {
    var result = List<EmoticonPack>.of(ownedPacks);

    for (var space in room.client.spaces
        .where((element) => element.containsRoom(room.identifier))) {
      var component = space.getComponent<MatrixSpaceEmoticonComponent>();
      if (component != null) {
        result.addAll(component.ownedPacks.where((e) => !result.contains(e)));
      }
    }

    var globalComponent = room.client.getComponent<EmoticonComponent>();
    if (globalComponent != null) {
      for (var pack in globalComponent.globalPacks()) {
        if (!result.contains(pack)) {
          result.add(pack);
        }
      }
    }

    if (globalComponent != null) {
      result
          .addAll(globalComponent.ownedPacks.where((e) => !result.contains(e)));
    }

    if (includeUnicode) result.addAll(UnicodeEmojis.packs!);

    return result;
  }

  @override
  bool isGloballyAvailable(String packId) {
    return room.matrixRoom.client
        .isEmoticonPackGloballyAvailable(room.matrixRoom.id, packId);
  }

  Future<void> markAsGlobal(bool isGlobal, String packKey) async {
    if (isGlobal)
      return room.matrixRoom.client
          .addEmoticonRoomPack(room.matrixRoom.id, packKey);

    return room.matrixRoom.client
        .removeEmoticonRoomPack(room.matrixRoom.id, packKey);
  }

  Map<String, Map<String, String>> getEmotePacksFlat(
      matrix.ImagePackUsage emoticon) {
    var packs = availablePacks;

    var result = <String, Map<String, String>>{};

    for (var pack in packs) {
      var key = "${pack.displayName}-${pack.hashCode}";
      result[key] = <String, String>{};
      for (var emote in pack.emotes) {
        result[key]![emote.shortcode!] =
            (emote as MatrixEmoticon).emojiUrl.toString();
      }
    }

    return result;
  }
}
