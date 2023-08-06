import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/matrix/extensions/matrix_client_extensions.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;

import 'matrix_emoticon.dart';

abstract class MatrixEmoticonHelper {
  Map<String, dynamic> getState(String packKey);
  Map<String, dynamic> getAllStates();
  Future<void> setState(String packKey, Map<String, dynamic> content);
  Future<void> refreshState(String packKey);
  matrix.Client getClient();
  String getDefaultDisplayName();
  IconData? getDefaultIcon();
  String getOwnerId();
  ImageProvider? getDefaultImage();
  bool isMarkedAsGlobal(String packKey);

  Future<Map<String, dynamic>>? createEmoticonPack(
    String name,
    Uint8List? imageData,
  ) async {
    Uri? avatar;
    if (imageData != null) {
      avatar = await getClient().uploadContent(imageData);
    }

    var content = {
      "pack": {
        "display_name": name,
        if (avatar != null) "avatar_url": avatar.toString()
      }
    };

    String stateKey = name;
    var states = getAllStates();

    // Check for existing and empty state keys, and reuse those keys first
    for (var pair in states.entries) {
      if (pair.value.isEmpty) {
        stateKey = pair.key;
        print("Found existing key: $stateKey");
        break;
      }
    }

    print("Creating pack: $stateKey");

    await setState(stateKey, content);
    await refreshState(stateKey);

    var data = getState(stateKey);

    return {"key": stateKey, "content": data};
  }

  Future<void> deleteEmoticon(String packKey, String emoteName) async {
    var content = getState(packKey);

    if (content.containsKey('images')) {
      var images = content['images'] as Map<String, dynamic>;
      images.remove(emoteName);
      content['images'] = images;
    }

    return setState(packKey, content);
  }

  Future<void> deleteEmotionPack(String packKey) async {
    setState(packKey, {});
  }

  Future<void> renameEmoticon(
      String packKey, String emoteName, String newName) async {
    var content = getState(packKey);

    if (content.containsKey('images')) {
      var images = content['images'] as Map<String, dynamic>;
      var image = images[emoteName] as Map<String, dynamic>?;
      images.remove(emoteName);

      if (image != null) {
        image['display_name'] = newName;
        images[newName] = image;
      }

      content['images'] = images;
    }

    return setState(packKey, content);
  }

  Future<void> setEmoticonUsages(
      String packKey, String emoteName, List<String>? usages) async {
    var content = getState(packKey);

    if (content.containsKey('images')) {
      var images = content['images'] as Map<String, dynamic>;

      if (images.containsKey(emoteName)) {
        var emote = images[emoteName] as Map<String, dynamic>;

        emote.remove('usage');

        if (usages != null && usages.isNotEmpty) {
          emote['usage'] = usages;
        }

        images[emoteName] = emote;
      }

      content['images'] = images;
    }

    return setState(packKey, content);
  }

  Future<void> setPackUsages(String packKey, List<String>? usages) async {
    var content = getState(packKey);

    var pack = content['pack'] as Map<String, dynamic>?;

    if (pack == null) return;

    pack['usage'] = usages?.isEmpty == true ? null : usages;
    content['pack'] = pack;

    return setState(packKey, content);
  }

  Future<Map<String, dynamic>>? createEmoticon(
    String packKey,
    String emoteName,
    Uint8List data,
  ) async {
    var content = getState(packKey);

    Uri url = await getClient().uploadContent(data);

    if (content['images'] == null) {
      content['images'] = {};
    }

    if (content['images'][emoteName] == null) {
      content['images'][emoteName] = {};
    }
    content['images'][emoteName]['url'] = url.toString();
    content['images'][emoteName]['display_name'] = emoteName;

    await setState(packKey, content);
    return content;
  }

  Future<void> markAsGlobal(String packKey, bool isGlobal) async {}
}

class MatrixRoomEmoticonHelper extends MatrixEmoticonHelper {
  matrix.Room room;
  MatrixRoomEmoticonHelper(
    this.room,
  );

  @override
  Map<String, dynamic> getState(String packKey) {
    var states = getAllStates();
    var data = states[packKey];
    print(data);

    return data;
  }

  @override
  Map<String, dynamic> getAllStates() {
    if (!room.states.containsKey("im.ponies.room_emotes")) return {};

    var state =
        (room.states["im.ponies.room_emotes"] as Map<String, matrix.Event>);

    var result = <String, dynamic>{};

    for (var key in state.keys) {
      result[key] = state[key]!.content;
    }

    return result;
  }

  @override
  matrix.Client getClient() {
    return room.client;
  }

  @override
  String getDefaultDisplayName() {
    return room.getLocalizedDisplayname();
  }

  @override
  bool isMarkedAsGlobal(String packKey) {
    return room.client.isEmoticonPackGloballyAvailable(room.id, packKey);
  }

  @override
  String getOwnerId() {
    return room.id;
  }

  @override
  Future<void> setState(String packKey, Map<String, dynamic> content) async {
    print("Setting state: ");
    print(content);
    await room.client.setRoomStateWithKey(
        room.id, "im.ponies.room_emotes", packKey, content);

    print("Done");
  }

  @override
  ImageProvider? getDefaultImage() {
    return null;
  }

  @override
  IconData? getDefaultIcon() {
    return Icons.emoji_emotions;
  }

  @override
  Future<void> refreshState(String packKey) {
    return room.client.getRoomState(room.id);
  }
}

class MatrixPersonalEmoticonHelper extends MatrixEmoticonHelper {
  MatrixClient client;
  ImageProvider? userAvatar;
  MatrixPersonalEmoticonHelper(this.client, {this.userAvatar});

  @override
  Map<String, dynamic> getAllStates() {
    //These keys are kind of irrelevant, since they dont actually get used for
    //the state, its just easier this way
    var state = getState("personal");
    if (state.isEmpty) return {};
    return {"personal": state};
  }

  @override
  matrix.Client getClient() {
    return client.getMatrixClient();
  }

  @override
  String getDefaultDisplayName() {
    return client.user?.displayName ?? "Personal";
  }

  @override
  String getOwnerId() {
    return client.user!.identifier;
  }

  @override
  Map<String, dynamic> getState(String packKey) {
    return client
            .getMatrixClient()
            .accountData['im.ponies.user_emotes']
            ?.content ??
        {};
  }

  @override
  bool isMarkedAsGlobal(String packKey) {
    return true;
  }

  @override
  Future<void> setState(String packKey, Map<String, dynamic> content) {
    print("Setting personal emoticon data: ");
    print(content);

    return client.getMatrixClient().setAccountData(
        client.getMatrixClient().userID!, "im.ponies.user_emotes", content);
  }

  @override
  ImageProvider? getDefaultImage() {
    print("Getting default image:");
    print(userAvatar);
    return userAvatar;
  }

  @override
  IconData? getDefaultIcon() {
    return Icons.star;
  }

  @override
  Future<void> refreshState(String packKey) {
    var matrixClient = client.getMatrixClient();
    return matrixClient.getAccountData(
        matrixClient.userID!, "im.ponies.user_emotes");
  }
}

class MatrixEmoticonPack implements EmoticonPack {
  @override
  String get attribution => throw UnimplementedError();

  @override
  late String displayName;

  @override
  List<Emoticon> emotes = List.empty(growable: true);

  @override
  late String identifier;

  @override
  ImageProvider<Object>? image;

  @override
  IconData? icon;

  String get ownerId => helper.getOwnerId();

  @override
  Stream<int> get onEmoticonAdded => _onEmoticonAdded.stream;

  final StreamController<int> _onEmoticonAdded =
      StreamController<int>.broadcast();

  @override
  bool get isEmojiPack => _getUsage()?.contains("emoticon") ?? true;

  @override
  bool get isStickerPack => _getUsage()?.contains("sticker") ?? true;

  @override
  List<Emoticon> get emoji =>
      emotes.where((element) => element.isEmoji).toList();

  @override
  List<Emoticon> get stickers =>
      emotes.where((element) => element.isSticker).toList();

  late MatrixEmoticonHelper helper;

  MatrixEmoticonPack(this.identifier, this.helper) {
    var content = helper.getState(identifier);
    print("Got content:");
    print(content);

    displayName = "";

    var info = content['pack'] as Map<String, dynamic>?;
    if (info != null) {
      if (info.containsKey('display_name')) displayName = info['display_name'];

      if (info.containsKey('avatar_url')) {
        try {
          var uri = Uri.parse(info['avatar_url']);
          image = MatrixMxcImage(uri, helper.getClient());
        } catch (_) {}
      }
    }

    if (displayName == "") {
      displayName = helper.getDefaultDisplayName();
    }

    if (image == null) {
      image = helper.getDefaultImage();
      if (image == null) {
        icon = helper.getDefaultIcon();
      }
    }

    var images = content['images'] as Map<String, dynamic>?;

    bool isStickerPackCache = isStickerPack;
    bool isEmojiPackCache = isEmojiPack;
    if (images == null) return;

    for (var image in images.keys) {
      var url = images[image]['url'];

      var usages = images[image]['usage'] as List?;

      bool markedSticker = false;
      bool markedEmoji = false;
      if (usages != null) {
        markedSticker = usages.contains("sticker");
        markedEmoji = usages.contains("emoticon");
      }

      if (url != null) {
        var uri = Uri.parse(url);
        emotes.add(MatrixEmoticon(uri, helper.getClient(),
            shortcode: image,
            isEmojiPack: isEmojiPackCache,
            isStickerPack: isStickerPackCache,
            isMarkedEmoji: markedEmoji,
            isMarkedSticker: markedSticker));
      }
    }
  }

  List? _getUsage() {
    var info = helper.getState(identifier)['pack'] as Map<String, dynamic>?;
    if (info == null) return null;

    var usage = info.tryGet("usage") as List?;
    return usage;
  }

  @override
  Future<void> addEmoticon(
      {required String slug,
      String? shortcode,
      required Uint8List data,
      String? mimeType,
      bool? isEmoji,
      bool? isSticker}) async {
    var result = await helper.createEmoticon(identifier, shortcode!, data);
    if (result == null) return;
    var url = result['images'][shortcode]['url'];

    try {
      var uri = Uri.parse(url);
      var emote = MatrixEmoticon(uri, helper.getClient(), shortcode: shortcode);
      emotes.add(emote);
      _onEmoticonAdded.add(emotes.length - 1);
    } catch (_) {}
  }

  @override
  Future<void> deleteEmoticon(Emoticon emoticon) async {
    var emote = emoticon as MatrixEmoticon;
    await helper.deleteEmoticon(identifier, emote.shortcode!);
    emotes.remove(emoticon);
  }

  @override
  Future<void> renameEmoticon(Emoticon emoticon, String name) async {
    await helper.renameEmoticon(identifier, emoticon.shortcode!, name);
    (emoticon as MatrixEmoticon).setShortcode(name);
  }

  @override
  Future<void> markEmoticonAsEmoji(Emoticon emoticon, bool isEmoji) async {
    await helper.setEmoticonUsages(identifier, emoticon.shortcode!,
        [if (isEmoji) 'emoticon', if (emoticon.isMarkedSticker) 'sticker']);

    (emoticon as MatrixEmoticon).markAsEmoji(isEmoji);
  }

  @override
  Future<void> markEmoticonAsSticker(Emoticon emoticon, bool isSticker) async {
    await helper.setEmoticonUsages(identifier, emoticon.shortcode!,
        [if (emoticon.isMarkedEmoji) 'emoticon', if (isSticker) 'sticker']);

    (emoticon as MatrixEmoticon).markAsSticker(isSticker);
  }

  @override
  Future<void> markAsEmoji(bool isEmoji) async {
    await helper.setPackUsages(
        identifier, [if (isEmoji) 'emoticon', if (isStickerPack) 'sticker']);

    for (var emote in emotes) {
      (emote as MatrixEmoticon).markPackAsEmoji(isEmoji);
    }
  }

  @override
  Future<void> markAsSticker(bool isSticker) async {
    await helper.setPackUsages(
        identifier, [if (isEmojiPack) 'emoticon', if (isSticker) 'sticker']);

    for (var emote in emotes) {
      (emote as MatrixEmoticon).markPackAsSticker(isSticker);
    }
  }

  @override
  Future<void> markAsGlobal(bool isGlobal) async {
    helper.markAsGlobal(identifier, isGlobal);
  }

  @override
  bool get isGloballyAvailable => helper.isMarkedAsGlobal(identifier);
}
