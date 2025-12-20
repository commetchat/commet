import 'package:collection/collection.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/emoticon/dynamic_emoticon_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/components/emoticon_recent/recent_emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/debounce.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix_api_lite/model/basic_event.dart';

class MatrixRecentEmoticonComponent
    implements RecentEmoticonComponent<MatrixClient>, NeedsPostLoginInit {
  MatrixRecentEmoticonComponent(this.client);

  List<RecentEmoji> _reactionEmoji = List.empty(growable: true);
  List<RecentEmoji> _typedEmoji = List.empty(growable: true);

  Debouncer reactionDebouncer = Debouncer(delay: Duration(seconds: 5));
  Debouncer typedDebouncer = Debouncer(delay: Duration(seconds: 5));

  static const String reactionsKey = "chat.commet.recent_reaction_emoji";
  static const String typedKey = "chat.commet.recent_emoji";

  @override
  MatrixClient client;

  @override
  List<Emoticon> getRecentReactionEmoticon(Room room) {
    return toEmoticons(room, _reactionEmoji);
  }

  @override
  List<Emoticon> getRecentTypedEmoticon(Room room) {
    return toEmoticons(room, _typedEmoji);
  }

  @override
  void postLoginInit() {
    var data = client.matrixClient.accountData[reactionsKey];
    if (data != null) {
      _reactionEmoji = toRecentsList(data);
      Log.i("Got ${_reactionEmoji.length} recent reaction emoji");
    }

    var typedData = client.matrixClient.accountData[typedKey];
    if (typedData != null) {
      _typedEmoji = toRecentsList(typedData);
      Log.i("Got ${_typedEmoji.length} recently typed emoji");
    }
  }

  List<Emoticon> toEmoticons(Room room, List<RecentEmoji> emojis) {
    var result = List<Emoticon>.empty(growable: true);

    var comp = room.getComponent<RoomEmoticonComponent>();
    if (comp == null) {
      return [];
    }

    emojis.sort((a, b) => b.count.compareTo(a.count));

    var availablePacks = comp.availablePacks;
    for (var emote in emojis) {
      if (emote.customPackId == null && emote.customPackRoomId == null) {
        result.add(UnicodeEmoticon(emote.key));
      }

      if (emote.customPackId != null) {
        for (var pack in availablePacks) {
          if (emote.customPackRoomId != null) {
            if (pack.ownerId != emote.customPackRoomId) continue;
          }

          if (pack.identifier == emote.customPackId) {
            var emoticon = pack.getByShortcode(emote.key);
            if (emoticon != null) {
              result.add(emoticon);
            }
          }
        }
      }
    }
    "❤️👍👎😂🔥😭🤣✨🙏💀😍🥺🥰😊😵‍💫😵🤩😎😘😅👏😁🤠💔💖💙🩷🤍💕😢🤔😆🙄💪😉☺️👌🤗"
        .characters
        .map((i) => UnicodeEmoticon(i.toString()))
        .forEach((i) {
      if (result.contains(i) == false) {
        result.add(i);
      }
    });

    return result;
  }

  RecentEmoji? toRecentEmoji(Room room, Emoticon emoticon) {
    String? customPackid;
    String? customPackRoomId;
    String key = emoticon.key;

    if (emoticon is MatrixEmoticon) {
      if (emoticon.shortcode != null) {
        key = emoticon.shortcode!;
      }
      var comp = room.getComponent<RoomEmoticonComponent>();
      if (comp == null) {
        return null;
      }

      for (var pack in comp.availablePacks) {
        if (pack is DynamicEmoticonPack) continue;

        if (pack.emotes.contains(emoticon)) {
          customPackid = pack.identifier;
          if (customPackid != "im.ponies.user_emotes")
            customPackRoomId = pack.ownerId;
          break;
        }
      }
    }

    return RecentEmoji(
        key: key,
        customPackId: customPackid,
        customPackRoomId: customPackRoomId);
  }

  @override
  Future<void> reactedEmoticon(Room room, Emoticon emoticon) async {
    var emoji = toRecentEmoji(room, emoticon);
    if (emoji == null) return;

    _reactionEmoji = addToList(emoji, _reactionEmoji);
    reactionDebouncer.run(() => storeRecentReactions());
  }

  @override
  Future<void> typedEmoticon(Room room, Emoticon emoticon) async {
    var emoji = toRecentEmoji(room, emoticon);
    if (emoji == null) return;

    _typedEmoji = addToList(emoji, _typedEmoji);
    typedDebouncer.run(() => storeRecentlyTyped());
  }

  List<RecentEmoji> addToList(RecentEmoji emoji, List<RecentEmoji> list) {
    const maxLen = 30;

    if (list.length > maxLen) {
      list = list.sublist(0, maxLen);
    }

    var existing = list.firstWhereOrNull((i) =>
        i.customPackId == emoji.customPackId &&
        i.customPackRoomId == emoji.customPackRoomId &&
        i.key == emoji.key);

    if (existing != null) {
      existing.count++;
    } else {
      list.insert(0, emoji);
    }

    return list;
  }

  Future<void> storeRecentReactions() async {
    var content = {
      "recent_emoji": _reactionEmoji.map((i) => i.toJson()).toList()
    };
    client.matrixClient
        .setAccountData(client.matrixClient.userID!, reactionsKey, content);
  }

  Future<void> storeRecentlyTyped() async {
    var content = {"recent_emoji": _typedEmoji.map((i) => i.toJson()).toList()};

    await client.matrixClient
        .setAccountData(client.matrixClient.userID!, typedKey, content);
  }

  List<RecentEmoji> toRecentsList(BasicEvent data) {
    var content = data.content;
    var list = content["recent_emoji"] as List<dynamic>?;
    if (list == null) return [];

    return list.map((i) => RecentEmoji.fromjson(i)).nonNulls.toList();
  }

  @override
  Future<void> clear() async {
    _reactionEmoji = List.empty(growable: true);
    _typedEmoji = List.empty(growable: true);

    await storeRecentReactions();
    await storeRecentlyTyped();
  }
}

class RecentEmoji {
  RecentEmoji(
      {required this.key,
      this.customPackId,
      this.customPackRoomId,
      this.count = 1});

  String key;
  String? customPackId;
  String? customPackRoomId;
  int count;

  Map<String, dynamic> toJson() {
    return {
      "key": key,
      if (customPackId != null) "state_key": customPackId,
      if (customPackRoomId != null) "room_id": customPackRoomId,
      "count": count,
    };
  }

  static RecentEmoji? fromjson(Map<String, dynamic> data) {
    var key = data["key"] as String?;
    var packId = data["state_key"] as String?;
    var customPackRoomId = data["room_id"] as String?;
    var count = data["count"] as int? ?? 1;
    if (key == null) return null;
    return RecentEmoji(
        key: data["key"],
        customPackId: packId,
        customPackRoomId: customPackRoomId,
        count: count);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is! RecentEmoji) {
      return false;
    }

    return other.customPackId == customPackId &&
        other.customPackRoomId == customPackRoomId &&
        other.key == key;
  }

  @override
  int get hashCode {
    return "${key}_${customPackId}_${customPackRoomId}".hashCode;
  }
}
