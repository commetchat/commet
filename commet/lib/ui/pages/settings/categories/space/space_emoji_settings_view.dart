// Discord-style "server emoji" list for a space: upload several images at
// once, rename inline, remove, with a fixed quota. Members see it read-only.
// Editing goes through SpaceEmoticonComponent, which writes to the space's
// default im.ponies pack.
import 'dart:async';

import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/components/emoticon/space_emoji_library.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/mime.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:tiamat/tiamat.dart' as tiamat;

class SpaceEmojiSettingsView extends StatefulWidget {
  const SpaceEmojiSettingsView(
      {required this.component, required this.editable, super.key});

  final SpaceEmoticonComponent component;
  final bool editable;

  @override
  State<SpaceEmojiSettingsView> createState() => _SpaceEmojiSettingsViewState();
}

class _SpaceEmojiSettingsViewState extends State<SpaceEmojiSettingsView> {
  StreamSubscription? _sub;
  String? _uploadStatus;
  String? _error;

  SpaceEmoticonComponent get component => widget.component;

  @override
  void initState() {
    super.initState();
    _sub = component.onStateChanged.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _upload() async {
    final picked = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true, allowMultiple: true);
    if (picked == null) return;

    setState(() => _error = null);
    final failures = <String>[];

    for (final (i, file) in picked.files.indexed) {
      if (!mounted) return;
      setState(() =>
          _uploadStatus = 'Uploading ${i + 1} of ${picked.files.length}...');

      final data = file.bytes;
      if (data == null) {
        failures.add('${file.name}: could not read the file');
        continue;
      }

      try {
        await component.addEmoji(
          component.suggestShortcode(file.name),
          data,
          mimeType: Mime.lookupType(file.name, data: data),
          filename: file.name,
        );
      } catch (e, s) {
        Log.onError(e, s, content: 'Failed to upload space emoji');
        failures.add('${file.name}: ${_friendlyError(e)}');
      }
    }

    if (mounted) {
      setState(() {
        _uploadStatus = null;
        _error = failures.isEmpty ? null : failures.join('\n');
      });
    }
  }

  Future<String?> _rename(Emoticon emoji, String name) async {
    try {
      if (SpaceEmojiLibrary.validateShortcode(name) == emoji.shortcode) {
        return null;
      }
      await component.renameEmoji(emoji, name);
      return null;
    } catch (e, s) {
      Log.onError(e, s, content: 'Failed to rename space emoji');
      return _friendlyError(e);
    }
  }

  Future<void> _remove(Emoticon emoji) async {
    final confirm = await AdaptiveDialog.confirmation(context,
        prompt: 'Remove :${emoji.shortcode}: from this space?',
        dangerous: true);
    if (confirm != true) return;

    try {
      await component.removeEmoji(emoji);
    } catch (e, s) {
      Log.onError(e, s, content: 'Failed to remove space emoji');
      if (mounted) setState(() => _error = _friendlyError(e));
    }
  }

  String _friendlyError(Object e) {
    if (e is SpaceEmojiError) return e.message;
    if (e is matrix.MatrixException) {
      if (e.error == matrix.MatrixError.M_FORBIDDEN) {
        return 'You are not allowed to change this space\'s emoji';
      }
      if (e.error == matrix.MatrixError.M_TOO_LARGE) {
        return 'The image is too large for the homeserver';
      }
      return 'The homeserver rejected the request: ${e.errorMessage}';
    }
    return 'Something went wrong';
  }

  @override
  Widget build(BuildContext context) {
    final emoji = component.availableEmoji;
    final used = component.usedEmojiSlots;
    final quota = component.emojiQuota;
    final full = used >= quota;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const tiamat.Text.labelEmphasised('Server emojis'),
                  tiamat.Text.labelLow('$used of $quota slots used'),
                ],
              ),
            ),
            if (widget.editable)
              tiamat.Button(
                text: 'Add emoji',
                onTap: full || _uploadStatus != null ? null : _upload,
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: used / quota),
        ),
        if (widget.editable)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: tiamat.Text.labelLow(
                'PNG, GIF or WebP. Names use letters, numbers and underscores. '
                'Every member can use these emoji in any room of the space.'),
          ),
        if (_uploadStatus != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: tiamat.Text.label(_uploadStatus!),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: tiamat.Text.error(_error!),
          ),
        const SizedBox(height: 8),
        if (emoji.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: tiamat.Text.labelLow('No emoji yet.'),
          ),
        for (final e in emoji)
          _SpaceEmojiRow(
            key: ValueKey(e.shortcode),
            emoji: e,
            editable: widget.editable,
            onRename: (name) => _rename(e, name),
            onRemove: () => _remove(e),
          ),
      ],
    );
  }
}

class _SpaceEmojiRow extends StatefulWidget {
  const _SpaceEmojiRow({
    required this.emoji,
    required this.editable,
    required this.onRename,
    required this.onRemove,
    super.key,
  });

  final Emoticon emoji;
  final bool editable;

  /// Returns an error message, or null on success.
  final Future<String?> Function(String name) onRename;
  final VoidCallback onRemove;

  @override
  State<_SpaceEmojiRow> createState() => _SpaceEmojiRowState();
}

class _SpaceEmojiRowState extends State<_SpaceEmojiRow> {
  late final _controller = TextEditingController(text: widget.emoji.shortcode);
  final _focus = FocusNode();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _save();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Focus is also lost when the row is removed.
    if (_saving || !mounted) return;
    setState(() => _saving = true);
    final error = await widget.onRename(_controller.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
      if (error != null) _controller.text = widget.emoji.shortcode!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Image(image: widget.emoji.image!, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: widget.editable
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _controller,
                            focusNode: _focus,
                            enabled: !_saving,
                            maxLength: SpaceEmojiLibrary.maxShortcodeLength,
                            decoration: const InputDecoration(
                              isDense: true,
                              counterText: '',
                              prefixText: ':',
                              suffixText: ':',
                            ),
                            onSubmitted: (_) => _focus.unfocus(),
                          ),
                          if (_error != null) tiamat.Text.error(_error!),
                        ],
                      )
                    : tiamat.Text.label(':${widget.emoji.shortcode}:'),
              ),
              if (widget.editable)
                tiamat.IconButton(
                  icon: Icons.delete_outline,
                  size: 20,
                  onPressed: _saving ? null : widget.onRemove,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
