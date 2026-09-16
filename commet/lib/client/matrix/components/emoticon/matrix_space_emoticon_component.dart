import 'dart:typed_data';

import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/components/emoticon/space_emoji_library.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_component.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon_state_manager.dart';
import 'package:commet/client/matrix/extensions/matrix_client_extensions.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_space.dart';

class MatrixSpaceEmoticonComponent extends MatrixEmoticonComponent
    implements SpaceEmoticonComponent<MatrixClient, MatrixSpace> {
  @override
  MatrixSpace space;

  @override
  bool get canCreatePack => space.permissions.canEditRoomEmoticons;

  @override
  String get ownerId => space.identifier;

  @override
  String get ownerDisplayName => space.displayName;

  MatrixSpaceEmoticonComponent(
    MatrixClient client,
    this.space,
  ) : super(client, MatrixEmoticonRoomStateManager(space.matrixRoom));

  @override
  bool isGloballyAvailable(String packId) {
    return space.matrixRoom.client
        .isEmoticonPackGloballyAvailable(space.matrixRoom.id, packId);
  }

  SpaceEmojiLibrary get _library => SpaceEmojiLibrary(state.getAllStates());

  @override
  List<Emoticon> get availableEmoji => _library.emoji
      .map((e) => MatrixEmoticon(
            Uri.parse(e.url),
            client.getMatrixClient(),
            shortcode: e.shortcode,
            usage: EmoticonUsage.emoji,
            packUsage: EmoticonUsage.emoji,
          ))
      .toList();

  @override
  int get emojiQuota => SpaceEmojiLibrary.quota;

  @override
  int get usedEmojiSlots => _library.usedSlots;

  @override
  String suggestShortcode(String filename) =>
      SpaceEmojiLibrary.shortcodeFromFilename(
          filename, _library.takenShortcodes);

  @override
  Future<void> addEmoji(String shortcode, Uint8List data,
      {String? mimeType, String? filename}) async {
    // Validate before uploading, so a rejected name doesn't cost an upload.
    _library.add(shortcode, "");

    final url = await client
        .getMatrixClient()
        .uploadContent(data, contentType: mimeType, filename: filename);

    await _send(_library.add(shortcode, url.toString()));
  }

  @override
  Future<void> renameEmoji(Emoticon emoji, String shortcode) =>
      _send(_library.rename(emoji.shortcode!, shortcode));

  @override
  Future<void> removeEmoji(Emoticon emoji) =>
      _send(_library.remove(emoji.shortcode!));

  Future<void> _send(SpaceEmojiEdit edit) =>
      state.setState(edit.packKey, edit.content);
}
