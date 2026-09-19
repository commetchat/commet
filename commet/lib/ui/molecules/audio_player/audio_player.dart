import 'dart:async';

import 'package:commet/cache/file_provider.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayer extends StatefulWidget {
  const AudioPlayer(
    {required this.file, this.fileName, this.fileSize, super.key});

  final String? fileName;
  final int? fileSize;
  final FileProvider file;

  @override
  State<AudioPlayer> createState() => _AudioPlayerState();
}

enum AudioPlayerState {
  paused,
  loading,
  playing,
}

class _AudioPlayerState extends State<AudioPlayer> {
  Player player = Player();
  late List<StreamSubscription> subs;

  @override
  void initState() {
    super.initState();

    _loadPreferences();

    subs = [
      player.stream.playing.listen(onPlayingChanged),
      player.stream.position.listen(onPositionChanged),
      player.stream.volume.listen(onVolumeChanged),
      if (widget.file.onProgressChanged != null)
        widget.file.onProgressChanged!.listen(onDownloadProgressChanged),
    ];
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }

    player.dispose();

    super.dispose();
  }

  var state = AudioPlayerState.paused;

  bool dragging = false;

  double displayPosition = 0;
  double? downloadProgress;

  bool isMuted = false;
  double volume = 50;
  double preMuteVolume = 50;

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_muted', isMuted);
    await prefs.setDouble('audio_volume', preMuteVolume);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMuted = prefs.getBool('audio_muted') ?? false;
    final savedVolume = prefs.getDouble('audio_volume') ?? 100.0;

    setState(() {
      volume = savedVolume;
      preMuteVolume = savedVolume;
    });
    player.setVolume(savedVolume);
    if (savedMuted) {
      toggleMute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.fileName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.audio_file,
                        size: 20,
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      tiamat.Text.labelLow(widget.fileName!),
                    ],
                  ),
                  if (widget.fileSize != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
                    child: tiamat.Text.labelLow(
                      TextUtils.readableFileSize(widget.fileSize!)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
              child: tiamat.Seperator(
                padding: 0,
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 8,
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: state == AudioPlayerState.loading
                  ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: downloadProgress,
                      )),
                  )
                  : tiamat.IconButton(
                    icon: state == AudioPlayerState.paused
                    ? Icons.play_arrow
                    : Icons.pause,
                    onPressed: onPlayButtonPressed,
                  )),
                Expanded(
                  child: tiamat.Slider(
                    value: displayPosition,
                    onChangeStart: (value) {
                      dragging = true;
                    },
                    onChangeEnd: (value) {
                      dragging = false;

                      var position = player.state.duration * value;

                      player.seek(position);
                    },
                    onChanged: (value) => setState(() {
                      displayPosition = value;
                    }),
                  )),
                tiamat.IconButton(
                  icon: isMuted ? Icons.volume_mute : volume == 0 ? Icons.volume_off : Icons.volume_up,
                  onPressed: (() {
                    toggleMute();
                    _savePreferences();
                  }),
                ),
                SizedBox(
                  width: 100,
                  child: tiamat.Slider(
                    value: volume / 100,
                    onChanged: (value) => setVolume(value * 100),
                    onChangeEnd: (value) => _savePreferences(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  onPlayButtonPressed() {
    if (state == AudioPlayerState.paused) {
      if (player.state.playlist.medias.isEmpty) {
        setState(() {
          state = AudioPlayerState.loading;
          loadAudio();
        });
      } else {
        player.play();
      }
    }

    if (state == AudioPlayerState.playing) {
      player.pause();
      setState(() {
        state = AudioPlayerState.paused;
      });
    }
  }

  void onPlayingChanged(bool event) {
    if (event) {
      setState(() {
        state = AudioPlayerState.playing;
      });
    } else {
      setState(() {
        state = AudioPlayerState.paused;
      });
    }
  }

  void loadAudio() async {
    var uri = await widget.file.resolve();

    if (uri != null) {
      player.open(Media(uri.toString()));
      player.setPlaylistMode(PlaylistMode.none);
    }

    setState(() {
      state = AudioPlayerState.playing;
    });
  }

  void onDownloadProgressChanged(DownloadProgress event) {
    print(event);
    setState(() {
      downloadProgress = event.downloaded.toDouble() / event.total.toDouble();
    });
  }

  void onPositionChanged(Duration event) {
    if (!dragging) {
      setState(() {
        var pos = event.inMilliseconds.toDouble() /
            player.state.duration.inMilliseconds.toDouble();

        if (pos >= 0 && pos <= 1) {
          displayPosition = pos;
        }
      });
    }
  }

  void toggleMute() {
    if (!isMuted) {
      setState(() {
        isMuted = true;
        preMuteVolume = volume;
        volume = 0;
      });
      player.setVolume(0.0);
    } else {
      setState(() {
        isMuted = false;
        volume = preMuteVolume;
      });
      player.setVolume(volume);
    }
  }

  void setVolume(double value) {
    setState(() {
      volume = value;
      preMuteVolume = value;
      isMuted = false;
    });
    player.setVolume(value);
  }

  void onVolumeChanged(double event) {
    setState(() {
      volume = event;
    });
  }
}
