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

import 'package:meta/meta.dart';

/// A message received from the agent.
@immutable
class ReceivedMessage {
  const ReceivedMessage({
    required this.id,
    required this.timestamp,
    required this.content,
  });

  final String id;
  final DateTime timestamp;
  final ReceivedMessageContent content;

  ReceivedMessage copyWith({
    String? id,
    DateTime? timestamp,
    ReceivedMessageContent? content,
  }) {
    return ReceivedMessage(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      content: content ?? this.content,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceivedMessage && other.id == id && other.timestamp == timestamp && other.content == content;
  }

  @override
  int get hashCode => Object.hash(id, timestamp, content);
}

/// Base class for message content types that can be received from the agent.
sealed class ReceivedMessageContent {
  const ReceivedMessageContent();

  /// Textual representation of the content.
  String get text;
}

/// A transcript emitted by the agent.
class AgentTranscript extends ReceivedMessageContent {
  const AgentTranscript(this.text);

  @override
  final String text;

  @override
  bool operator ==(Object other) => other is AgentTranscript && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// A transcript emitted for the user (e.g., speech-to-text).
class UserTranscript extends ReceivedMessageContent {
  const UserTranscript(this.text);

  @override
  final String text;

  @override
  bool operator ==(Object other) => other is UserTranscript && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// A message that originated from user input (loopback).
class UserInput extends ReceivedMessageContent {
  const UserInput(this.text);

  @override
  final String text;

  @override
  bool operator ==(Object other) => other is UserInput && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// A message sent to the agent.
@immutable
class SentMessage {
  const SentMessage({
    required this.id,
    required this.timestamp,
    required this.content,
  });

  final String id;
  final DateTime timestamp;
  final SentMessageContent content;
}

/// Base class for message content types that can be sent to the agent.
sealed class SentMessageContent {
  const SentMessageContent();

  /// Textual representation of the content.
  String get text;
}

/// User-provided text input.
class SentUserInput extends SentMessageContent {
  const SentUserInput(this.text);

  @override
  final String text;
}
