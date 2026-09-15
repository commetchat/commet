// Copyright 2025 LiveKit, Inc.
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

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:uuid/uuid.dart';

import '../audio/audio_frame_capture.dart';
import '../core/room.dart';
import '../events.dart';
import '../logger.dart';
import '../participant/local.dart';
import '../support/byte_ring_buffer.dart';
import '../support/reusable_completer.dart';
import '../track/local/audio.dart';
import '../types/data_stream.dart';
import '../types/other.dart';
import '../types/participant_state.dart';

typedef PreConnectOnError = void Function(Object error);

/// Captures and buffers microphone audio before a room connection completes.
///
/// This is used by `Room.withPreConnectAudio` to reduce perceived latency for
/// voice agent experiences: the microphone can begin recording while the app is
/// still connecting and dispatching an agent, then the buffered audio is sent
/// once the agent becomes active.
///
/// Audio is buffered in memory and bounded by [defaultMaxSize].
/// If it overflows, the oldest audio is dropped until the agent is ready.
class PreConnectAudioBuffer {
  /// Topic used to send the buffered audio stream to agents.
  static const String dataTopic = 'lk.agent.pre-connect-audio-buffer';

  static const int defaultMaxSize = 10 * 1024 * 1024; // 10MB
  static const int defaultSampleRate = 24000; // Hz
  static const int defaultChunkSize = 64 * 1024; // 64KB chunks for streaming

  // Reference to the room
  final Room _room;

  // Internal states
  bool _isRecording = false;
  bool _isBufferSent = false;

  LocalAudioTrack? _localTrack;
  AudioFrameCapture? _audioCapture;
  StreamSubscription? _streamSubscription;

  PreConnectOnError? _onError;
  final int _requestSampleRate;
  int? _renderedSampleRate;
  int? _renderedChannels;

  bool _nativeRecordingStarted = false;
  bool _hasLoggedOverflow = false;
  final ByteRingBuffer _buffer = ByteRingBuffer(defaultMaxSize);
  Timer? _timeoutTimer;
  CancelListenFunc? _participantStateListener;

  final ReusableCompleter<void> _agentReadyManager = ReusableCompleter<void>();

  PreConnectAudioBuffer(
    this._room, {
    PreConnectOnError? onError,
    int sampleRate = defaultSampleRate,
  })  : _onError = onError,
        _requestSampleRate = sampleRate;

  /// Whether pre-connect recording is currently active.
  bool get isRecording => _isRecording;

  /// Number of buffered bytes currently stored.
  int get bufferedSize => _buffer.length;

  /// The local audio track used for recording while pre-connecting.
  LocalAudioTrack? get localTrack => _localTrack;

  Future<LocalTrackPublishedEvent>? _localTrackPublishedEvent;

  /// Completes when an agent becomes active and the buffer has been sent.
  ///
  /// If the configured timeout elapses before an agent becomes active, this
  /// future completes with an error.
  Future<void> get agentReadyFuture => _agentReadyManager.future;

  /// Starts capturing audio into an in-memory buffer.
  ///
  /// [timeout] controls how long to wait for an agent to become active. When the
  /// agent becomes active, buffered audio is sent automatically and
  /// [agentReadyFuture] completes. If the timeout is reached first,
  /// [agentReadyFuture] completes with an error and callers should [reset] the
  /// buffer.
  ///
  /// Ensure microphone permissions are granted before calling this.
  /// Audio capture may fail without permissions.
  Future<void> startRecording({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (_isRecording) {
      logger.warning('Already recording');
      return;
    }
    _isRecording = true;

    // Set up timeout for agent readiness
    _agentReadyManager.setTimer(timeout, timeoutReason: 'Agent did not become ready within timeout');

    _localTrack = await LocalAudioTrack.create();
    logger.fine('[Preconnect audio] created local track ${_localTrack!.mediaStreamTrack.id}');

    final rendererId = Uuid().v4();
    logger.info('Starting audio renderer with rendererId: $rendererId');

    _audioCapture = createAudioFrameCapture();
    final result = await _audioCapture!.start(
      track: _localTrack!.mediaStreamTrack,
      rendererId: rendererId,
      sampleRate: _requestSampleRate,
      channels: 1,
      format: AudioFormat.Int16,
    );

    if (!result) {
      final error = StateError('Failed to start audio renderer ($result)');
      logger.severe('[Preconnect audio] $error');
      _onError?.call(error);
      await stopRecording(withError: error);
      await _localTrack?.stop();
      _localTrack = null;
      throw error;
    }

    if (!kIsWeb) {
      await webrtc.NativeAudioManagement.startLocalRecording();
      _nativeRecordingStarted = true;
    }

    logger.info('startAudioRenderer result: $result');

    _streamSubscription = _audioCapture!.frameStream.listen((frame) {
      if (!_isRecording) return;

      _renderedSampleRate = frame.sampleRate;
      _renderedChannels = frame.channels;

      final didOverflow = _buffer.write(frame.data);
      if (didOverflow && !_hasLoggedOverflow) {
        _hasLoggedOverflow = true;
        logger.warning(
          '[Preconnect audio] buffer exceeded ${defaultMaxSize ~/ 1024}KB, dropping oldest audio until agent is ready',
        );
      }
    });

    // Listen for agent readiness and send the buffer when active.
    _participantStateListener = _room.events.on<ParticipantStateUpdatedEvent>(
        filter: (event) => event.participant.kind == ParticipantKind.AGENT && event.state == ParticipantState.active,
        (event) async {
      logger.info('[Preconnect audio] Agent is active: ${event.participant.identity}');
      try {
        await sendAudioData(agents: [event.participant.identity]);
        _agentReadyManager.complete();
      } catch (error) {
        _agentReadyManager.completeError(error);
        _onError?.call(error);
      }
    });

    _localTrackPublishedEvent = _room.events.waitFor<LocalTrackPublishedEvent>(
      duration: Duration(seconds: 10),
      filter: (event) => event.participant == _room.localParticipant,
    );

    // Emit the started event
    _room.events.emit(PreConnectAudioBufferStartedEvent(
      sampleRate: _requestSampleRate,
      timeout: timeout,
    ));
  }

  /// Stops recording and releases audio capture resources.
  ///
  /// If [withError] is provided, [agentReadyFuture] completes with that error.
  /// Otherwise, [agentReadyFuture] completes successfully (if not already
  /// completed).
  Future<void> stopRecording({Object? withError}) async {
    if (!_isRecording) return;
    _isRecording = false;

    // Cancel the stream subscription.
    await _streamSubscription?.cancel();
    _streamSubscription = null;

    // Stop the audio capture.
    await _audioCapture?.stop();
    _audioCapture = null;

    // Only stop native recording on error, the room's mic track still uses it.
    if (withError != null && _nativeRecordingStarted) {
      await webrtc.NativeAudioManagement.stopLocalRecording();
    }

    _nativeRecordingStarted = false;

    // Complete agent ready future if not already completed
    withError != null ? _agentReadyManager.completeError(withError) : _agentReadyManager.complete();

    // Emit the stopped event
    _room.events.emit(PreConnectAudioBufferStoppedEvent(
      bufferedSize: _buffer.length,
      isBufferSent: _isBufferSent,
    ));

    logger.info('[Preconnect audio] stopped recording');
  }

  /// Stops recording and clears buffered audio and listeners so the instance
  /// can be reused.
  Future<void> reset() async {
    await stopRecording();
    _timeoutTimer?.cancel();
    await _participantStateListener?.call();
    _participantStateListener = null;
    _buffer.clear();

    // Keep the local track because the Room still uses it.
    _localTrack = null;

    _agentReadyManager.reset();
    _localTrackPublishedEvent = null;

    // Reset the _isSent flag to allow data sending on next use
    _isBufferSent = false;
    _hasLoggedOverflow = false;
    _renderedSampleRate = null;
    _renderedChannels = null;

    logger.info('[Preconnect audio] reset');
  }

  /// Disposes this buffer (alias for [reset]).
  Future<void> dispose() async {
    await reset();
    logger.info('[Preconnect audio] disposed');
  }

  /// Sends the currently buffered audio to one or more agent identities.
  ///
  /// This is a one shot operation.
  /// Repeated calls are ignored after the buffer has been sent.
  ///
  /// The stream is written to [topic] (default: [dataTopic]) and includes
  /// attributes that help the agent interpret the raw audio payload.
  Future<void> sendAudioData({
    required List<String> agents,
    String topic = dataTopic,
  }) async {
    if (_isBufferSent) return;
    if (agents.isEmpty) return;

    final sampleRate = _renderedSampleRate;
    final rawChannels = _renderedChannels ?? 1;
    final channels = rawChannels > 0 ? rawChannels : 1;
    if (sampleRate == null) {
      logger.severe('[Preconnect audio] renderedSampleRate is null');
      return;
    }
    if (rawChannels <= 0) {
      logger.warning('[Preconnect audio] Invalid rendered channels: $rawChannels. Falling back to mono.');
    }

    // Wait for local track published event
    final localTrackPublishedEvent = await _localTrackPublishedEvent;
    logger.info('[Preconnect audio] localTrackPublishedEvent: $localTrackPublishedEvent');

    final localTrackSid = localTrackPublishedEvent?.publication.track?.sid;
    if (localTrackSid == null) {
      logger.severe('[Preconnect audio] localTrackPublishedEvent is null');
      return;
    }

    logger.info('[Preconnect audio] sending audio data to ${agents.map((e) => e).join(', ')} agent(s)');

    final data = _buffer.takeBytes();
    logger.info('[Preconnect audio] data.length: ${data.length}, bytes.length: ${_buffer.length}');

    _isBufferSent = true;

    final streamOptions = StreamBytesOptions(
      topic: topic,
      attributes: {
        'sampleRate': sampleRate.toString(),
        'channels': channels.toString(),
        'commonFormat': 'int16',
        'trackId': localTrackSid,
      },
      totalSize: data.length,
      destinationIdentities: agents,
    );

    logger.info('[Preconnect audio] streamOptions: $streamOptions');

    final writer = await _room.localParticipant!.streamBytes(streamOptions);
    await writer.write(data);
    await writer.close();

    // Compute seconds of audio data sent
    final int bytesPerSample = 2; // 16-bit audio
    final int bytesPerFrame = bytesPerSample * channels;
    final int totalFrames = data.length ~/ bytesPerFrame;
    final double secondsOfAudio = totalFrames / sampleRate;

    logger.info(
        '[Preconnect audio] sent ${(data.length / 1024).toStringAsFixed(1)}KB of audio (${secondsOfAudio.toStringAsFixed(2)} seconds) to ${agents} agent(s)');
  }

  /// Updates the callback invoked when pre-connect audio fails.
  void setErrorHandler(PreConnectOnError? onError) {
    _onError = onError;
  }
}
