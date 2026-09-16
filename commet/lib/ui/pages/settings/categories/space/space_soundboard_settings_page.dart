// Space Soundboard admin page: add/edit/remove effects.
//
// Only visible to users with canManage (power levels). Enforced again in
// MatrixSpaceSoundboardComponent — hiding UI is not the security boundary.
// Import flow: paste MyInstants URL -> resolve -> validate -> upload to MXC
// -> store per-sound state event. Audio is then served from the homeserver,
// never hotlinked per-click.
// Each sound has an admin volume slider (fallback for sounds normalization
// gets wrong) with a preview at the volume a call would use.
import 'dart:async';

import 'package:commet/client/components/soundboard/myinstants_network_probe.dart';
import 'package:commet/client/components/soundboard/myinstants_resolver.dart';
import 'package:commet/client/components/soundboard/soundboard_component.dart';
import 'package:commet/client/components/soundboard/soundboard_constraints.dart';
import 'package:commet/client/components/soundboard/soundboard_import_service.dart';
import 'package:commet/client/components/soundboard/soundboard_validation.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/client/matrix/components/soundboard/matrix_space_soundboard_component.dart';
import 'package:commet/client/matrix/components/soundboard/soundboard_preview_player.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_call_controller.dart';
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
  final _preview = SoundboardPreviewPlayer(
      userVolume: () => SoundboardCallController.userVolume);
  double _volume = 1.0;
  bool _busy = false;
  bool _previewBusy = false;
  String? _error;

  // Audio fetched for preview, reused by "Add sound" while the link is the
  // same so it is downloaded once.
  FetchedAudio? _fetched;
  String? _fetchedUrl;

  @override
  void dispose() {
    _preview.dispose();
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
              const SizedBox(height: 8),
              _SoundVolumeField(
                volume: _volume,
                previewing: _previewBusy,
                onChanged: (v) {
                  setState(() => _volume = v);
                  final fetched = _fetched;
                  if (fetched != null) {
                    _preview.setSoundGain(fetched.normalizedGain * v);
                  }
                },
                onPreview: _busy || _previewBusy ? null : _previewNewSound,
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
                onTap: _busy || _previewBusy ? null : _addSound,
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
                          Text(s.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(child: tiamat.Text.label(s.name)),
                          if (s.volume != 1.0)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: tiamat.Text.labelLow(
                                  _SoundVolumeField.percent(s.volume)),
                            ),
                          tiamat.IconButton(
                            icon: Icons.edit,
                            size: 16,
                            onPressed: () => _editDialog(s),
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

  Future<FetchedAudio> _fetch(String url) async {
    if (_fetched != null && _fetchedUrl == url) return _fetched!;
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
    _fetched = fetched;
    _fetchedUrl = url;
    return fetched;
  }

  Future<void> _previewNewSound() async {
    setState(() {
      _previewBusy = true;
      _error = null;
    });
    try {
      final fetched = await _fetch(_urlCtrl.text);
      await _preview.playBytes(
          fetched.bytes, fetched.mimeType, fetched.normalizedGain * _volume);
    } on MyInstantsValidationError catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e));
    } catch (e, s) {
      Log.onError(e, s, content: 'Soundboard preview failed: $e');
      if (mounted) setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _previewBusy = false);
    }
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
      final fetched = await _fetch(url);
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
        volume: _volume,
        sourceUrl: MyInstantsResolver.normalizeUrl(url),
      );
      Log.i('Soundboard import: added "$name"');
      await _preview.stop();
      _urlCtrl.clear();
      _nameCtrl.clear();
      _emojiCtrl.clear();
      _fetched = null;
      _fetchedUrl = null;
      if (mounted) setState(() => _volume = 1.0);
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

  Future<void> _editDialog(SoundboardSound sound) async {
    final nameCtrl = TextEditingController(text: sound.name);
    final emojiCtrl = TextEditingController(text: sound.emoji);
    final preview = SoundboardPreviewPlayer(
        userVolume: () => SoundboardCallController.userVolume);
    var volume = sound.volume;
    var previewing = false;
    String? previewError;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit sound'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tiamat.TextInput(label: 'Name', controller: nameCtrl),
              const SizedBox(height: 8),
              tiamat.TextInput(label: 'Emoji', controller: emojiCtrl),
              const SizedBox(height: 8),
              _SoundVolumeField(
                volume: volume,
                previewing: previewing,
                onChanged: (v) {
                  setDialogState(() => volume = v);
                  preview.setSoundGain(sound.normalizedGain * v);
                },
                onPreview: previewing
                    ? null
                    : () async {
                        setDialogState(() {
                          previewing = true;
                          previewError = null;
                        });
                        try {
                          final uri =
                              await SoundboardCallController.resolvePlayableUri(
                                  widget.soundboard.client, sound);
                          await preview.playUri(
                              uri, sound.normalizedGain * volume);
                        } catch (e, s) {
                          Log.onError(e, s,
                              content: 'Soundboard preview failed: $e');
                          previewError = _friendlyError(e);
                        }
                        if (ctx.mounted) {
                          // Also shows previewError, set above.
                          setDialogState(() => previewing = false);
                        }
                      },
              ),
              if (previewError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: tiamat.Text.error(previewError!),
                ),
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
      ),
    );
    await preview.dispose();
    if (ok == true) {
      try {
        await widget.soundboard.updateSound(sound.soundId,
            name: nameCtrl.text, emoji: emojiCtrl.text, volume: volume);
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

/// "Sound volume" slider (0..200 %) with a preview button.
class _SoundVolumeField extends StatelessWidget {
  final double volume;
  final bool previewing;
  final ValueChanged<double> onChanged;
  final VoidCallback? onPreview;

  const _SoundVolumeField({
    required this.volume,
    required this.previewing,
    required this.onChanged,
    required this.onPreview,
  });

  static String percent(double volume) => '${(volume * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const tiamat.Text.labelLow('Sound volume'),
        Row(
          children: [
            const Icon(Icons.volume_up, size: 18),
            Expanded(
              child: tiamat.Slider(
                min: 0.0,
                max: SoundboardConstraints.maxSoundVolume,
                // 5 % steps.
                divisions: (SoundboardConstraints.maxSoundVolume * 20).round(),
                value: volume,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 48,
              child: tiamat.Text.labelLow(percent(volume)),
            ),
            SizedBox(
              width: 110,
              child: tiamat.Button.secondary(
                text: 'Preview',
                isLoading: previewing,
                onTap: onPreview,
              ),
            ),
          ],
        ),
      ],
    );
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
