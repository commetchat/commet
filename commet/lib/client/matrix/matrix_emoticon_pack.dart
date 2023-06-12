import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/matrix/extensions/matrix_room_extensions.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/utils/emoji/emoticon.dart';
import 'package:commet/utils/emoji/emoji_pack.dart';
import 'package:commet/client/matrix/matrix_emoticon.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart' as matrix;

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
  IconData? get icon => null;

  late matrix.Room _matrixRoom;

  String stateKey;

  String get ownedRoomId => _matrixRoom.id;

  @override
  Stream<int> get onEmoticonAdded => _onEmoticonAdded.stream;

  final StreamController<int> _onEmoticonAdded =
      StreamController<int>.broadcast();

  MatrixEmoticonPack(
      this.stateKey, matrix.Room room, Map<String, dynamic> content) {
    var info = content['pack'] as Map<String, dynamic>?;
    _matrixRoom = room;

    if (info != null) {
      displayName = info['display_name'];
      identifier = stateKey;
      var avatarUrl = info['avatar_url'];
      try {
        var uri = Uri.parse(avatarUrl);
        image = MatrixMxcImage(uri, room.client);
      } catch (_) {}
    } else {
      displayName = _matrixRoom.getLocalizedDisplayname();
      if (_matrixRoom.avatar != null) {
        image = MatrixMxcImage(_matrixRoom.avatar!, room.client);
      }
    }

    var images = content['images'] as Map<String, dynamic>?;
    if (images == null) return;

    for (var image in images.keys) {
      var url = images[image]['url'];
      if (url != null) {
        var uri = Uri.parse(url);
        emotes.add(MatrixEmoticon(uri, room.client, shortcode: image));
      }
    }
  }

  @override
  Future<void> addEmoticon(
      {required String slug,
      String? shortcode,
      required Uint8List data,
      String? mimeType}) async {
    var result = await _matrixRoom.createEmoticon(stateKey, shortcode!, data);
    if (result == null) return;
    var url = result['images'][shortcode]['url'];
    try {
      var uri = Uri.parse(url);
      var emote = MatrixEmoticon(uri, _matrixRoom.client, shortcode: shortcode);
      emotes.add(emote);
      _onEmoticonAdded.add(emotes.length - 1);
    } catch (_) {}
  }

  static List<MatrixEmoticonPack> getPacks(matrix.Room room) {
    var state = room.states['im.ponies.room_emotes'];
    List<MatrixEmoticonPack> items = List.empty(growable: true);
    if (state != null && state.isNotEmpty) {
      for (var key in state.keys) {
        var value = state[key]!;
        if (value.content['pack'] == null && value.content['images'] == null)
          continue;
        var pack = MatrixEmoticonPack(key, room, value.content);
        items.add(pack);
      }
    }

    return items;
  }

  @override
  Future<void> deleteEmoticon(Emoticon emoticon) async {
    var emote = emoticon as MatrixEmoticon;
    await _matrixRoom.deleteEmoticon(identifier, emote.shortcode!);
    emotes.remove(emoticon);
  }

  @override
  Future<void> renameEmoticon(Emoticon emoticon, String name) async {
    await _matrixRoom.renameEmoticon(identifier, emoticon.shortcode!, name);
    (emoticon as MatrixEmoticon).setShortcode(name);
  }
}
