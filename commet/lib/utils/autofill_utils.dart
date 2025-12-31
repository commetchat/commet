import 'package:commet/client/client.dart';
import 'package:commet/client/components/command/command_component.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';

class AutofillUtils {
  static List<AutofillSearchResult> search(String string, Room room) {
    List<AutofillSearchResult>? results;

    var firstChar = string.characters.first;

    string = string.substring(1);
    switch (firstChar) {
      case "/":
        results = searchCommands(string, room);
        string = string.replaceAll("/", "");
        break;
      case "#":
        results = searchRooms(string, room);
        break;
      case "@":
        results = searchUsers(string, room);
        break;
      case ":":
        results = searchEmoticon(string, room);
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

  static List<AutofillSearchResult> searchEmoticon(String string, Room room) {
    var emoticons = room.getComponent<RoomEmoticonComponent>();
    if (emoticons == null) {
      return [];
    }

    var result = List<AutofillSearchResult>.empty(growable: true);

    for (var pack in emoticons.availableEmoji) {
      result.addAll(pack.search(string, 20).map((e) {
        return AutofillSearchResultEmoticon(e.shortcode!, e.slug, e);
      }));

      if (result.length >= 20) {
        break;
      }
    }

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

  AutofillSearchResultEmoticon(super.result, super.slug, this.emoticon);
}
