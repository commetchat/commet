// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:synchronized/synchronized.dart' as sync;

import '../hardware/hardware.dart';
import '../logger.dart';
import '../support/native.dart';
import '../support/native_audio.dart';
import '../support/platform.dart';
import 'local/local.dart';
import 'remote/remote.dart';

enum AudioTrackState {
  none,
  remoteOnly,
  localOnly,
  localAndRemote,
}

typedef ConfigureNativeAudioFunc = Future<NativeAudioConfiguration> Function(AudioTrackState state);

// it's possible to set custom function here to customize audio session configuration
ConfigureNativeAudioFunc onConfigureNativeAudio = defaultNativeAudioConfigurationFunc;

final _trackCounterLock = sync.Lock();
AudioTrackState _audioTrackState = AudioTrackState.none;

AudioTrackState get audioTrackState => _audioTrackState;

int _localTrackCount = 0;
int _remoteTrackCount = 0;

mixin LocalAudioManagementMixin on LocalTrack, AudioTrack {
  @override
  Future<bool> onPublish() async {
    final didUpdate = await super.onPublish();
    if (didUpdate) {
      // update counter
      await _trackCounterLock.synchronized(() async {
        _localTrackCount++;
        await _onAudioTrackCountDidChange();
      });
    }
    return didUpdate;
  }

  @override
  Future<bool> onUnpublish() async {
    final didUpdate = await super.onUnpublish();
    if (didUpdate) {
      // update counter
      await _trackCounterLock.synchronized(() async {
        _localTrackCount--;
        await _onAudioTrackCountDidChange();
      });
    }
    return didUpdate;
  }
}
mixin RemoteAudioManagementMixin on RemoteTrack, AudioTrack {
  /// Start playing audio track. On web platform, create an audio element and
  /// start playback
  @override
  Future<bool> start() async {
    final didStart = await super.start();
    if (didStart) {
      await _trackCounterLock.synchronized(() async {
        _remoteTrackCount++;
        await _onAudioTrackCountDidChange();
      });
    }
    return didStart;
  }

  @override
  Future<bool> stop() async {
    final didStop = await super.stop();
    if (didStop) {
      await _trackCounterLock.synchronized(() async {
        _remoteTrackCount--;
        await _onAudioTrackCountDidChange();
      });
    }
    return didStop;
  }
}

Future<void> _onAudioTrackCountDidChange() async {
  logger.fine('onAudioTrackCountDidChange: '
      'local: $_localTrackCount, remote: $_remoteTrackCount');

  final newState = _computeAudioTrackState();

  if (_audioTrackState != newState) {
    _audioTrackState = newState;
    logger.fine('didUpdateSate: $_audioTrackState');

    NativeAudioConfiguration? config;
    if (lkPlatformIs(PlatformType.iOS)) {
      // Only iOS for now...
      config = await onConfigureNativeAudio.call(_audioTrackState);

      if (Hardware.instance.forceSpeakerOutput) {
        config = config.copyWith(
          appleAudioCategoryOptions: {
            ...?config.appleAudioCategoryOptions,
            AppleAudioCategoryOption.defaultToSpeaker,
          },
        );
      }
    }

    if (config != null) {
      logger.fine('configuring for ${_audioTrackState} using ${config}...');
      try {
        if (Hardware.instance.isAutomaticConfigurationEnabled) {
          logger.fine('configuring native audio...');
          await Native.configureAudio(config);
        }
      } catch (error) {
        logger.warning('failed to configure ${error}');
      }
    }
  }
}

AudioTrackState _computeAudioTrackState() {
  if (_localTrackCount > 0 && _remoteTrackCount == 0) {
    return AudioTrackState.localOnly;
  } else if (_localTrackCount == 0 && _remoteTrackCount > 0) {
    return AudioTrackState.remoteOnly;
  } else if (_localTrackCount > 0 && _remoteTrackCount > 0) {
    return AudioTrackState.localAndRemote;
  }
  // Default
  return AudioTrackState.none;
}

Future<NativeAudioConfiguration> defaultNativeAudioConfigurationFunc(AudioTrackState state) async {
  if (state == AudioTrackState.none) {
    return NativeAudioConfiguration.soloAmbient;
  } else if (state == AudioTrackState.remoteOnly && Hardware.instance.preferSpeakerOutput) {
    return NativeAudioConfiguration.playback;
  }

  return Hardware.instance.preferSpeakerOutput
      ? NativeAudioConfiguration.playAndRecordSpeaker
      : NativeAudioConfiguration.playAndRecordReceiver;
}

class NativeAudioManagement {
  static Future<void> start() async {
    // Audio configuration for Android.
    if (lkPlatformIs(PlatformType.android)) {
      if (Native.bypassVoiceProcessing) {
        await rtc.Helper.setAndroidAudioConfiguration(rtc.AndroidAudioConfiguration.media);
      } else {
        await rtc.Helper.setAndroidAudioConfiguration(rtc.AndroidAudioConfiguration.communication);
      }
    }
  }

  static Future<void> stop() async {
    if (lkPlatformIs(PlatformType.android)) {
      await rtc.Helper.clearAndroidCommunicationDevice();
    }
  }
}
