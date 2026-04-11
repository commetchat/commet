import 'package:commet/client/client.dart';
import 'package:commet/client/components/command/command_component.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';

class AutofillUtils {
  static List<AutofillSearchResult> search(String string, Client client,
      {Room? room}) {
    List<AutofillSearchResult>? results;

    var firstChar = string.characters.first;

    string = string.substring(1);
    switch (firstChar) {
      case "/":
        results = room != null ? searchCommands(string, room) : null;
        string = string.replaceAll("/", "");
        break;
      case "#":
        results = room != null ? searchRooms(string, room) : null;
        break;
      case "@":
        results = room != null ? searchUsers(string, room) : null;
        break;
      case ":":
        results = searchEmoticon(string, client: client, room: room);
        break;

      default:
        break;
    }

    if (results == null) {
      return [];
    }

    var fuzzy = Fuzzy<AutofillSearchResult>(results,
        options: FuzzyOptions(keys: [
          WeightedKey(
              name: "result",
              getter: (result) {
                return result.result;
              },
              weight: 1)
        ]));

    return fuzzy.search(string, 20).map((e) {
      return e.item;
    }).toList();
  }

  static List<AutofillSearchResult> searchCommands(String string, Room room) {
    var component = room.client.getComponent<CommandComponent>();
    if (component != null) {
      var result = component.getCommands();
      return result.map((e) => AutofillSearchResult(e, "/$e")).toList();
    } else {
      return [];
    }
  }

  static List<AutofillSearchResult> searchUsers(String string, Room room) {
    var result =
        room.memberIds.map((e) => room.getMemberOrFallback(e)).toList();
    return result
        .map((e) => AutofillSearchResultAvatar(
            e.displayName, e.identifier, e.avatar, e.defaultColor))
        .toList();
  }

  static List<AutofillSearchResult> searchRooms(String string, Room room) {
    var rooms = List<Room>.empty(growable: true);
    var spaces = room.client.spaces
        .where((element) => element.containsRoom(room.identifier));
    for (var space in spaces) {
      for (var room in space.rooms) {
        if (!rooms.contains(room)) {
          rooms.add(room);
        }
      }
    }
    var fuzzy = Fuzzy<Room>(rooms,
        options: FuzzyOptions(keys: [
          WeightedKey(
              name: "displayName",
              getter: (result) {
                return result.displayName;
              },
              weight: 1)
        ]));

    return fuzzy.search(string, 20).map((e) {
      return AutofillSearchResult(e.item.displayName, e.item.identifier);
    }).toList();
  }

  static List<AutofillSearchResult> searchEmoticon(String string,
      {int limit = 20,
      required Client client,
      Room? room,
      double threshold = 0.2}) {
    List<EmoticonPack>? packs;
    if (room != null) {
      var emoticons = room.getComponent<RoomEmoticonComponent>();
      packs = emoticons?.availableEmoji;
    } else {
      var emoticons = client.getComponent<EmoticonComponent>();
      packs = emoticons?.availablePacks;
    }

    if (packs == null) return [];

    var result = List<AutofillSearchResultEmoticon>.empty(growable: true);

    for (var pack in packs) {
      var fuzzy = Fuzzy<Emoticon>(pack.emoji,
          options: FuzzyOptions(threshold: threshold, keys: [
            WeightedKey(
                name: "shortcode",
                getter: (obj) {
                  return obj.shortcode ?? "";
                },
                weight: 1)
          ]));

      var searchResult = fuzzy.search(string, limit);

      result.addAll(searchResult.map((e) {
        return AutofillSearchResultEmoticon(
            e.item.shortcode!, e.item.slug, e.item,
            score: e.score);
      }));

      if (result.length >= limit) {
        break;
      }
    }

    result.sort((a, b) => a.score.compareTo(b.score));

    return result;
  }
}

class AutofillSearchResult {
  String result;
  String slug;
  AutofillSearchResult(this.result, this.slug);
}

class AutofillSearchResultAvatar extends AutofillSearchResult {
  ImageProvider? image;
  Color fallbackColor;

  AutofillSearchResultAvatar(
      super.result, super.slug, this.image, this.fallbackColor);
}

class AutofillSearchResultEmoticon extends AutofillSearchResult {
  Emoticon emoticon;
  double score;
  AutofillSearchResultEmoticon(super.result, super.slug, this.emoticon,
      {this.score = 0});
}
