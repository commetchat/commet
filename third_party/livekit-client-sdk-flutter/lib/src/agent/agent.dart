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

import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'package:collection/collection.dart';

import '../json/agent_attributes.dart';
import '../participant/participant.dart';
import '../participant/remote.dart';
import '../track/remote/audio.dart';
import '../track/remote/video.dart';
import '../types/other.dart';
import 'constants.dart';

/// Represents a LiveKit Agent.
///
/// The [Agent] class models the state of a LiveKit agent within a [Session].
/// It exposes information about the agent's connection status, conversational
/// state, and the media tracks that belong to the agent. Consumers should
/// observe [Agent] to update their UI when the agent connects, disconnects,
/// or transitions between conversational states such as listening, thinking,
/// and speaking.
///
/// The associated [Participant]'s attributes are inspected to derive the
/// agent-specific metadata (such as [agentState]). Audio and avatar video
/// tracks are picked from the agent participant and its associated avatar
/// worker (if any).
class Agent extends ChangeNotifier {
  Agent();

  AgentFailure? get error => _error;
  AgentFailure? _error;

  /// The current conversational state of the agent.
  AgentState? get agentState => _agentState;
  AgentState? _agentState;

  /// The agent's audio track, if available.
  RemoteAudioTrack? get audioTrack => _audioTrack;
  RemoteAudioTrack? _audioTrack;

  /// The agent's avatar video track, if available.
  RemoteVideoTrack? get avatarVideoTrack => _avatarVideoTrack;
  RemoteVideoTrack? _avatarVideoTrack;

  /// Indicates whether the agent is connected and ready for conversation.
  bool get isConnected {
    if (_state != _AgentLifecycle.connected) {
      return false;
    }
    return switch (_agentState) {
      AgentState.listening || AgentState.thinking || AgentState.speaking => true,
      _ => false,
    };
  }

  /// Whether the agent is buffering audio prior to connecting.
  bool get isBuffering => _state == _AgentLifecycle.connecting && _isBuffering;

  /// Whether the agent can currently listen for user input.
  bool get canListen {
    if (_state == _AgentLifecycle.connecting) {
      return _isBuffering;
    }
    if (_state == _AgentLifecycle.connected) {
      return switch (_agentState) {
        AgentState.listening || AgentState.thinking || AgentState.speaking => true,
        _ => false,
      };
    }
    return false;
  }

  /// Whether the agent is pending initialization.
  bool get isPending {
    if (_state == _AgentLifecycle.connecting) {
      return !_isBuffering;
    }
    if (_state == _AgentLifecycle.connected) {
      return switch (_agentState) {
        AgentState.idle || AgentState.initializing => true,
        _ => false,
      };
    }
    return false;
  }

  /// Whether the agent finished or failed its session.
  bool get isFinished => _state == _AgentLifecycle.disconnected || _state == _AgentLifecycle.failed;

  _AgentLifecycle _state = _AgentLifecycle.disconnected;
  bool _isBuffering = false;

  /// Marks the agent as disconnected.
  void disconnected() {
    if (_state == _AgentLifecycle.disconnected &&
        _agentState == null &&
        _audioTrack == null &&
        _avatarVideoTrack == null &&
        _error == null) {
      return;
    }
    _state = _AgentLifecycle.disconnected;
    _isBuffering = false;
    _agentState = null;
    _audioTrack = null;
    _avatarVideoTrack = null;
    _error = null;
    notifyListeners();
  }

  /// Marks the agent as connecting.
  void connecting({required bool buffering}) {
    _state = _AgentLifecycle.connecting;
    _isBuffering = buffering;
    _error = null;
    notifyListeners();
  }

  /// Marks the agent as failed.
  void failed(AgentFailure failure) {
    _state = _AgentLifecycle.failed;
    _isBuffering = false;
    _error = failure;
    notifyListeners();
  }

  /// Updates the agent with information from the connected [participant].
  void connected(RemoteParticipant participant) {
    final AgentState? nextAgentState = _readAgentState(participant);
    final RemoteAudioTrack? nextAudioTrack = _resolveAudioTrack(participant);
    final RemoteVideoTrack? nextAvatarTrack = _resolveAvatarVideoTrack(participant);

    final bool shouldNotify = _state != _AgentLifecycle.connected ||
        _agentState != nextAgentState ||
        !identical(_audioTrack, nextAudioTrack) ||
        !identical(_avatarVideoTrack, nextAvatarTrack) ||
        _error != null ||
        _isBuffering;

    _state = _AgentLifecycle.connected;
    _isBuffering = false;
    _error = null;
    _agentState = nextAgentState;
    _audioTrack = nextAudioTrack;
    _avatarVideoTrack = nextAvatarTrack;

    if (shouldNotify) {
      notifyListeners();
    }
  }

  AgentState? _readAgentState(Participant participant) {
    final rawState = participant.attributes[lkAgentStateAttributeKey];
    if (rawState == null) {
      return null;
    }
    switch (rawState) {
      case 'idle':
        return AgentState.idle;
      case 'initializing':
        return AgentState.initializing;
      case 'listening':
        return AgentState.listening;
      case 'speaking':
        return AgentState.speaking;
      case 'thinking':
        return AgentState.thinking;
      default:
        return null;
    }
  }

  RemoteAudioTrack? _resolveAudioTrack(RemoteParticipant participant) {
    final publication = participant.audioTrackPublications.firstWhereOrNull(
      (pub) => pub.source == TrackSource.microphone,
    );
    return publication?.track;
  }

  RemoteVideoTrack? _resolveAvatarVideoTrack(RemoteParticipant participant) {
    final avatarWorker = _findAvatarWorker(participant);
    if (avatarWorker == null) {
      return null;
    }
    final publication = avatarWorker.videoTrackPublications.firstWhereOrNull(
      (pub) => pub.source == TrackSource.camera,
    );
    return publication?.track;
  }

  RemoteParticipant? _findAvatarWorker(RemoteParticipant participant) {
    final publishOnBehalf = participant.identity;
    final room = participant.room;
    return room.remoteParticipants.values.firstWhereOrNull(
      (p) => p.attributes[lkPublishOnBehalfAttributeKey] == publishOnBehalf,
    );
  }
}

/// Describes why an [Agent] failed to connect.
enum AgentFailure {
  /// The agent did not connect within the allotted timeout.
  timeout,

  /// The agent left the room unexpectedly.
  left;

  /// A human-readable error message.
  String get message => switch (this) {
        AgentFailure.timeout => 'Agent did not connect',
        AgentFailure.left => 'Agent left the room unexpectedly',
      };
}

enum _AgentLifecycle {
  disconnected,
  connecting,
  connected,
  failed,
}
