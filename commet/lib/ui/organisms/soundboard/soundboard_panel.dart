// Soundboard panel: grid of effects + single user volume control.
//
// Native Commet/Tiamat look (Tile + Text + IconButton + Slider). Each row
// shows emoji + name; tap plays instantly (optimistic local playback — no
// network wait for animation/feedback). Volume is ONE control for all
// effects (local-only preference); 0 = mute.
import 'package:commet/client/components/soundboard/soundboard_catalog.dart';
import 'package:commet/client/components/soundboard/soundboard_session.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class SoundboardPanel extends StatefulWidget {
  final SoundboardCatalog catalog;
  final SoundboardSession? session;
  final double volume01;
  final ValueChanged<double>? onVolumeChanged;

  const SoundboardPanel({
    super.key,
    required this.catalog,
    this.session,
    this.volume01 = 0.8,
    this.onVolumeChanged,
  });

  @override
  State<SoundboardPanel> createState() => _SoundboardPanelState();
}

class _SoundboardPanelState extends State<SoundboardPanel> {
  late double _volume = widget.volume01;
  String? _pressedId;

  @override
  void initState() {
    super.initState();
    widget.catalog.onChanged.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final sounds = widget.catalog.sounds;
    return tiamat.Panel(
      header: 'Soundboard',
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sounds.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: tiamat.Text.labelLow(
                    'No sounds yet. An admin can add some in Space settings.'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sounds.length,
                  itemBuilder: (context, i) {
                    final s = sounds[i];
                    final pressed = _pressedId == s.soundId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: AnimatedScale(
                        scale: pressed ? 0.96 : 1.0,
                        duration: const Duration(milliseconds: 90),
                        onEnd: () {
                          if (_pressedId == s.soundId && mounted) {
                            setState(() => _pressedId = null);
                          }
                        },
                        child: tiamat.Tile.low(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTapDown: (_) =>
                                setState(() => _pressedId = s.soundId),
                            onTapCancel: () =>
                                setState(() => _pressedId = null),
                            onTap: () {
                              // Instant feedback: animation + local play
                              // happen before any network round-trip.
                              widget.session?.trigger(s.soundId);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              child: Row(
                                children: [
                                  Text(s.name.isEmpty ? '' : s.emoji,
                                      style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: tiamat.Text.label(s.name)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.volume_up, size: 18),
                Expanded(
                  child: tiamat.Slider(
                    min: 0.0,
                    max: 1.0,
                    value: _volume.clamp(0.0, 1.0),
                    onChanged: (v) {
                      setState(() => _volume = v);
                      widget.onVolumeChanged?.call(v);
                    },
                  ),
                ),
                tiamat.Text.labelLow('${(_volume * 100).toInt()}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
