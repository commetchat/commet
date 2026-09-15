// Space Soundboard admin page: add/edit/remove effects.
//
// Only visible to users with canManage (power levels). Enforced again in
// MatrixSpaceSoundboardComponent — hiding UI is not the security boundary.
// Import flow: paste MyInstants URL -> resolve -> validate -> upload to MXC
// -> store per-sound state event. Audio is then served from the homeserver,
// never hotlinked per-click.
import 'package:commet/client/components/soundboard/soundboard_component.dart';
import 'package:commet/client/components/soundboard/soundboard_import_service.dart';
import 'package:commet/client/matrix/components/soundboard/matrix_space_soundboard_component.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class SpaceSoundboardSettingsPage extends StatefulWidget {
  final SpaceSoundboardComponent soundboard;
  const SpaceSoundboardSettingsPage({super.key, required this.soundboard});

  @override
  State<SpaceSoundboardSettingsPage> createState() =>
      _SpaceSoundboardSettingsPageState();
}

class _SpaceSoundboardSettingsPageState
    extends State<SpaceSoundboardSettingsPage> {
  final _urlCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _urlCtrl.dispose();
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.soundboard.canManage) {
      return const Center(
        child: tiamat.Text.labelLow(
            'Only space admins can manage the soundboard.'),
      );
    }
    return ListenableBuilder(
      listenable: _RebuildOnChange(widget.soundboard),
      builder: (context, _) {
        final sounds = widget.soundboard.sounds;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const tiamat.Text.labelEmphasised('Add sound from MyInstants'),
              const SizedBox(height: 8),
              tiamat.TextInput(
                label: 'MyInstants link',
                placeholder: 'https://www.myinstants.com/en/instant/...',
                controller: _urlCtrl,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: tiamat.TextInput(
                      label: 'Name',
                      placeholder: 'Airhorn',
                      controller: _nameCtrl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: tiamat.TextInput(
                      label: 'Emoji',
                      placeholder: '📢',
                      controller: _emojiCtrl,
                    ),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: tiamat.Text.error(_error!),
                ),
              const SizedBox(height: 8),
              tiamat.Button(
                text: 'Add sound',
                isLoading: _busy,
                onTap: _busy ? null : _addSound,
              ),
              const SizedBox(height: 16),
              tiamat.Text.labelEmphasised('Sounds (${sounds.length})'),
              const SizedBox(height: 8),
              for (final s in sounds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: tiamat.Tile.low(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Text(s.emoji,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(child: tiamat.Text.label(s.name)),
                          tiamat.IconButton(
                            icon: Icons.edit,
                            size: 16,
                            onPressed: () => _editDialog(s.soundId, s.name,
                                s.emoji),
                          ),
                          tiamat.IconButton(
                            icon: Icons.delete,
                            size: 16,
                            onPressed: () => _remove(s.soundId),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addSound() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = SoundboardImportService();
      final fetched = await service
          .importFromPageUrl(_urlCtrl.text.trim())
          .timeout(const Duration(seconds: 30));
      // Upload normalized bytes to the homeserver (MXC) — clients stream
      // from here, never from MyInstants per-click.
      final mx = (widget.soundboard as MatrixSpaceSoundboardComponent)
          .client;
      final mxc = await mx
          .getMatrixClient()
          .uploadContent(fetched.bytes, contentType: fetched.mimeType);
      await widget.soundboard.addSound(
        name: _nameCtrl.text,
        emoji: _emojiCtrl.text,
        mediaUri: mxc.toString(),
        mimeType: fetched.mimeType,
        durationMs: fetched.durationMs ?? 3000,
        normalizedGain: fetched.normalizedGain,
        sourceUrl: _urlCtrl.text.trim(),
      );
      _urlCtrl.clear();
      _nameCtrl.clear();
      _emojiCtrl.clear();
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(String soundId) async {
    try {
      await widget.soundboard.removeSound(soundId);
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    }
  }

  Future<void> _editDialog(
      String soundId, String name, String emoji) async {
    final nameCtrl = TextEditingController(text: name);
    final emojiCtrl = TextEditingController(text: emoji);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit sound'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            tiamat.TextInput(label: 'Name', controller: nameCtrl),
            const SizedBox(height: 8),
            tiamat.TextInput(label: 'Emoji', controller: emojiCtrl),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await widget.soundboard.updateSound(soundId,
            name: nameCtrl.text, emoji: emojiCtrl.text);
      } catch (e) {
        if (mounted) setState(() => _error = _friendlyError(e));
      }
    }
    nameCtrl.dispose();
    emojiCtrl.dispose();
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('Only myinstants.com')) {
      return 'Only myinstants.com links are supported.';
    }
    if (s.contains('too large')) return 'Audio file too large (max 1MB).';
    if (s.contains('too long')) return 'Audio too long (max 15 seconds).';
    if (s.contains('Could not find audio')) {
      return 'Could not find audio on that page. Check the link.';
    }
    if (s.contains('single emoji')) {
      return 'Emoji must be a single emoji.';
    }
    if (s.contains('markup') || s.contains('empty') || s.contains('long')) {
      return 'Invalid name.';
    }
    if (s.contains('permission') || s.contains('Permission')) {
      return 'You do not have permission to manage sounds.';
    }
    return 'Could not add sound. Check the link and try again.';
  }
}

/// Bridges SpaceSoundboardComponent.onChanged (Stream) to Listenable.
class _RebuildOnChange extends ChangeNotifier {
  _RebuildOnChange(SpaceSoundboardComponent soundboard) {
    soundboard.onChanged.listen((_) => notifyListeners());
  }
}
