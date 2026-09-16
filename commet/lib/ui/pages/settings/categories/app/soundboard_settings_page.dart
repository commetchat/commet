import 'dart:async';

import 'package:commet/client/components/soundboard/soundboard_component.dart';
import 'package:commet/client/components/soundboard/soundboard_sound.dart';
import 'package:commet/client/components/soundboard/soundboard_engine.dart';
import 'package:commet/client/matrix/components/soundboard/soundboard_player_factory.dart';
import 'package:commet/client/space.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/organisms/soundboard/soundboard_call_controller.dart';
import 'package:commet/ui/pages/settings/categories/app/double_preference_slider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

/// User soundboard settings: volume and the entrance sound played when
/// joining a voice channel.
class SoundboardSettingsPage extends StatefulWidget {
  const SoundboardSettingsPage({super.key});

  @override
  State<SoundboardSettingsPage> createState() => _SoundboardSettingsPageState();
}

class _SoundboardSettingsPageState extends State<SoundboardSettingsPage> {
  // Dropdown value for "All Spaces" / "None".
  static const String _any = '';

  final List<StreamSubscription> _subs = [];
  SoundboardPlayer? _previewPlayer;
  static const _previewInstanceId = 'entrance-sound-preview';

  String get headerSoundboardVolume => Intl.message("Sound Effects",
      name: "headerSoundboardVolume",
      desc: "Header for the soundboard volume section in settings");

  String get labelSoundboardVolume => Intl.message("Sound effects volume",
      name: "labelSoundboardVolume",
      desc: "Label for the slider controlling soundboard volume");

  String get headerSoundboardEntranceSound => Intl.message("Entrance Sound",
      name: "headerSoundboardEntranceSound",
      desc: "Header for the entrance sound section in soundboard settings");

  String get labelSoundboardEntranceSoundDescription => Intl.message(
      "Pick a soundboard sound that plays for everyone in the call when you join a voice channel. Shift+click Join, or use \"Join Without Entrance Sound\" in the channel's menu, to join quietly.",
      name: "labelSoundboardEntranceSoundDescription",
      desc: "Explains what the entrance sound setting does");

  String get labelSoundboardEntranceSpace => Intl.message("Choose a space",
      name: "labelSoundboardEntranceSpace",
      desc: "Label for the space selector of the entrance sound");

  String get labelSoundboardEntranceAllSpaces => Intl.message("All spaces",
      name: "labelSoundboardEntranceAllSpaces",
      desc: "Entrance sound space option that applies to every space");

  String get labelSoundboardEntranceSound => Intl.message("Choose a sound",
      name: "labelSoundboardEntranceSound",
      desc: "Label for the sound selector of the entrance sound");

  String get labelSoundboardEntranceNone => Intl.message("None",
      name: "labelSoundboardEntranceNone",
      desc: "Entrance sound option that disables the entrance sound");

  String get labelSoundboardEntranceNoSounds => Intl.message(
      "None of your spaces have soundboard sounds yet.",
      name: "labelSoundboardEntranceNoSounds",
      desc: "Shown when no space has a soundboard to pick an entrance sound");

  @override
  void initState() {
    super.initState();
    _subs.add(preferences.onSettingChanged.listen((_) => _refresh()));
    for (final space in _soundboardSpaces()) {
      _subs.add(space.$2.onChanged.listen((_) => _refresh()));
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _previewPlayer?.stopAll();
    super.dispose();
  }

  /// Spaces with a soundboard, one entry per space id across accounts.
  List<(Space, SpaceSoundboardComponent)> _soundboardSpaces() {
    final seen = <String>{};
    final result = <(Space, SpaceSoundboardComponent)>[];
    for (final space in clientManager?.spaces ?? <Space>[]) {
      final comp = space.getComponent<SpaceSoundboardComponent>();
      if (comp == null || !seen.add(space.identifier)) continue;
      result.add((space, comp));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        tiamat.Panel(
          header: headerSoundboardVolume,
          mode: tiamat.TileType.surfaceContainerLow,
          child: DoublePreferenceSlider(
            preference: preferences.soundboardVolume,
            title: labelSoundboardVolume,
            min: 0,
            max: 100,
            numDecimals: 0,
            units: "%",
          ),
        ),
        tiamat.Panel(
          header: headerSoundboardEntranceSound,
          mode: tiamat.TileType.surfaceContainerLow,
          child: entranceSound(context),
        ),
      ],
    );
  }

  Widget entranceSound(BuildContext context) {
    final spaces = _soundboardSpaces();
    final savedSpaceId = preferences.soundboardEntranceSpaceId.value;
    final spaceId = spaces.any((e) => e.$1.identifier == savedSpaceId)
        ? savedSpaceId
        : null;

    // Sounds offered for the selected space, or for every space.
    final options =
        <SoundId, (Space, SpaceSoundboardComponent, SoundboardSound)>{};
    for (final (space, comp) in spaces) {
      if (spaceId != null && space.identifier != spaceId) continue;
      for (final sound in comp.sounds) {
        options[sound.soundId] = (space, comp, sound);
      }
    }
    final savedSoundId = preferences.soundboardEntranceSoundId.value;
    final soundId = options.containsKey(savedSoundId) ? savedSoundId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        tiamat.Text.labelLow(labelSoundboardEntranceSoundDescription),
        if (spaces.isEmpty)
          tiamat.Text.label(labelSoundboardEntranceNoSounds)
        else ...[
          tiamat.Text(labelSoundboardEntranceSpace),
          tiamat.DropdownSelector<String>(
            color: ColorScheme.of(context).surfaceContainerLow,
            items: [_any, ...spaces.map((e) => e.$1.identifier)],
            value: spaceId ?? _any,
            itemBuilder: (id) => tiamat.Text(id == _any
                ? labelSoundboardEntranceAllSpaces
                : spaces
                    .firstWhere((e) => e.$1.identifier == id)
                    .$1
                    .displayName),
            onItemSelected: (id) => _selectSpace(id, spaces),
          ),
          tiamat.Text(labelSoundboardEntranceSound),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: tiamat.DropdownSelector<String>(
                  color: ColorScheme.of(context).surfaceContainerLow,
                  items: [_any, ...options.keys],
                  value: soundId ?? _any,
                  itemBuilder: (id) {
                    if (id == _any) {
                      return tiamat.Text(labelSoundboardEntranceNone);
                    }
                    final (space, _, sound) = options[id]!;
                    final label = '${sound.emoji} ${sound.name}';
                    return tiamat.Text(spaceId == null
                        ? '$label (${space.displayName})'
                        : label);
                  },
                  onItemSelected: (id) => preferences.soundboardEntranceSoundId
                      .set(id == null || id == _any ? null : id),
                ),
              ),
              tiamat.IconButton(
                icon: Icons.play_arrow,
                size: 24,
                onPressed:
                    soundId == null ? null : () => _preview(options[soundId]!),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _selectSpace(
      String? id, List<(Space, SpaceSoundboardComponent)> spaces) async {
    final spaceId = id == null || id == _any ? null : id;
    await preferences.soundboardEntranceSpaceId.set(spaceId);
    if (spaceId == null) return;
    // A sound from another space can never play in the chosen one.
    final soundId = preferences.soundboardEntranceSoundId.value;
    final comp = spaces.firstWhere((e) => e.$1.identifier == spaceId).$2;
    if (soundId != null && comp.getById(soundId) == null) {
      await preferences.soundboardEntranceSoundId.set(null);
    }
  }

  /// Plays the sound for this user only, at the soundboard volume.
  Future<void> _preview(
      (Space, SpaceSoundboardComponent, SoundboardSound) option) async {
    final (space, comp, sound) = option;
    await _previewPlayer?.stopAll();
    // The platform player (Web Audio in the browser), so the preview goes
    // through the same path and gain as a call.
    final preview = createSoundboardPlayer(
      resolveSound: comp.getById,
      resolvePlayableUri: (s) =>
          SoundboardCallController.resolvePlayableUri(space.client, s),
      loadBytes: (s) => SoundboardCallController.loadBytes(space.client, s),
    );
    _previewPlayer = preview;
    // setVolumeFor also stores the listener volume for instances started later.
    await preview.setVolumeFor(
        _previewInstanceId, SoundboardCallController.userVolume);
    await preview.start(_previewInstanceId, sound.soundId);
  }
}
