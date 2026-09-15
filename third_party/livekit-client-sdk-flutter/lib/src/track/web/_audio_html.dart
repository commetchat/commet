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

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:web/web.dart' as web;

// ignore: implementation_imports
import 'package:dart_webrtc/src/media_stream_track_impl.dart'; // import_sorter: keep

const audioContainerId = 'livekit_audio_container';
const audioPrefix = 'livekit_audio_';

web.AudioContext _audioContext = web.AudioContext();
Map<String, web.Element> _audioElements = {};

Future<dynamic> startAudio(String id, rtc.MediaStreamTrack track) async {
  if (track is! MediaStreamTrackWeb) {
    return;
  }

  final elementId = audioPrefix + id;
  var audioElement = web.document.getElementById(elementId);
  if (audioElement == null) {
    audioElement = web.HTMLAudioElement()
      ..id = elementId
      ..autoplay = true;
    findOrCreateAudioContainer().append(audioElement);
    _audioElements[id] = audioElement;
  }
  if (!audioElement.instanceOfString('HTMLAudioElement')) {
    return;
  }
  final audio = audioElement as web.HTMLAudioElement;
  final audioStream = web.MediaStream();
  audioStream.addTrack(track.jsTrack);
  audioElement.srcObject = audioStream;
  return audio.play().toDart;
}

Future<bool> startAllAudioElement() async {
  for (final el in _audioElements.values.toList()) {
    if (el.instanceOfString('HTMLAudioElement')) {
      final audio = el as web.HTMLAudioElement;
      await audio.play().toDart;
    }
  }
  return _audioContext.state == 'running';
}

void stopAudio(String id) {
  final el = web.document.getElementById(audioPrefix + id);
  if (el != null) {
    if (el.instanceOfString('HTMLAudioElement')) {
      (el as web.HTMLAudioElement).srcObject = null;
    }
    _audioElements.remove(id);
    el.remove();
  }
}

web.HTMLDivElement findOrCreateAudioContainer() {
  final existing = web.document.getElementById(audioContainerId);
  if (existing != null) {
    if (existing.instanceOfString('HTMLDivElement')) {
      return existing as web.HTMLDivElement;
    }
    // If something else already exists with that ID, replace it to keep behavior sane.
    existing.remove();
  }

  final div = web.HTMLDivElement()
    ..id = audioContainerId
    ..style.display = 'none';

  web.document.body?.append(div);
  return div;
}

void setSinkId(String id, String deviceId) {
  final el = web.document.getElementById(audioPrefix + id);
  if (el != null && el.instanceOfString('HTMLAudioElement')) {
    final audio = el as web.HTMLAudioElement;
    if (audio.hasProperty('setSinkId'.toJS).toDart) {
      audio.setSinkId(deviceId);
    }
  }
}
