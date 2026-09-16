// Space Soundboard admin page: add/edit/remove effects.
//
// Only visible to users with canManage (power levels). Enforced again in
// MatrixSpaceSoundboardComponent — hiding UI is not the security boundary.
// Import flow: paste MyInstants URL -> resolve -> validate -> upload to MXC
// -> store per-sound state event. Audio is then served from the homeserver,
// never hotlinked per-click.
import 'dart:async';

import 'package:commet/client/components/soundboard/myinstants_network_probe.dart';
import 'package:commet/client/components/soundboard/myinstants_resolver.dart';
import 'package:commet/client/components/soundboard/soundboard_component.dart';
import 'package:commet/client/components/soundboard/soundboard_import_service.dart';
import 'package:commet/client/components/soundboard/soundboard_validation.dart';
import 'package:commet/client/matrix/components/soundboard/matrix_space_soundboard_component.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;
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
  late final _changes = _RebuildOnChange(widget.soundboard);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _changes.dispose();
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
      listenable: _changes,
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
                placeholder:
                    'https://www.myinstants.com/en/instant/... (page or .mp3)',
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
    final url = _urlCtrl.text;
    try {
      // Reject bad input before downloading or uploading anything.
      final name = SoundboardValidator.sanitizeName(_nameCtrl.text);
      final emoji = SoundboardValidator.sanitizeEmoji(_emojiCtrl.text);
      final service = SoundboardImportService(
          log: (line) => Log.i('Soundboard import: $line'));
      final FetchedAudio fetched;
      try {
        // Each request inside is bounded by SoundboardConstraints.httpTimeout.
        fetched = await service.importFromPageUrl(url);
      } on MyInstantsRequestError {
        if (!BuildConfig.WEB) unawaited(_probeNetwork(url));
        rethrow;
      }
      // Upload normalized bytes to the homeserver (MXC) — clients stream
      // from here, never from MyInstants per-click.
      final mx = (widget.soundboard as MatrixSpaceSoundboardComponent)
          .client
          .getMatrixClient();
      final mxc =
          await mx.uploadContent(fetched.bytes, contentType: fetched.mimeType);
      Log.i('Soundboard import: uploaded ${fetched.bytes.length} bytes '
          'as $mxc');
      await widget.soundboard.addSound(
        name: name,
        emoji: emoji,
        mediaUri: mxc.toString(),
        mimeType: fetched.mimeType,
        durationMs: fetched.durationMs ?? 3000,
        normalizedGain: fetched.normalizedGain,
        sourceUrl: MyInstantsResolver.normalizeUrl(url),
      );
      Log.i('Soundboard import: added "$name"');
      _urlCtrl.clear();
      _nameCtrl.clear();
      _emojiCtrl.clear();
    } on MyInstantsValidationError catch (e) {
      Log.w('Soundboard import failed: $e');
      if (mounted) setState(() => _error = _friendlyError(e));
    } on SoundboardValidationError catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } catch (e, s) {
      Log.onError(e, s, content: 'Soundboard import failed: $e');
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // TEMPORARY: see myinstants_network_probe.dart.
  Future<void> _probeNetwork(String url) {
    final page = Uri.tryParse(MyInstantsResolver.normalizeUrl(url));
    final homeserver = (widget.soundboard as MatrixSpaceSoundboardComponent)
        .client
        .getMatrixClient()
        .homeserver;
    return probeNetwork([
      if (page != null && MyInstantsResolver.isAllowedUrl(page.toString()))
        page
      else
        Uri.parse('https://www.myinstants.com/'),
      if (homeserver != null)
        homeserver.replace(path: '/_matrix/client/versions'),
    ], (line) => Log.i('Soundboard import $line'));
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
    // Both validation errors carry messages written for the admin.
    if (e is MyInstantsValidationError) return e.message;
    if (e is SoundboardValidationError) return e.message;
    if (e is matrix.MatrixException) {
      if (e.error == matrix.MatrixError.M_FORBIDDEN) {
        return 'You do not have permission to manage sounds.';
      }
      if (e.error == matrix.MatrixError.M_TOO_LARGE) {
        return 'The homeserver rejected the file as too large.';
      }
      return 'The homeserver rejected the request: ${e.errorMessage}';
    }
    if (e is StateError) return e.message;
    return 'Could not add sound: $e';
  }
}

/// Bridges SpaceSoundboardComponent.onChanged (Stream) to Listenable.
class _RebuildOnChange extends ChangeNotifier {
  late final StreamSubscription<void> _subscription;

  _RebuildOnChange(SpaceSoundboardComponent soundboard) {
    _subscription = soundboard.onChanged.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
