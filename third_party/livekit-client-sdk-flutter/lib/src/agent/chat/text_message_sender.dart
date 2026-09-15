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

import 'package:uuid/uuid.dart';

import '../../core/room.dart';
import '../../participant/local.dart';
import '../../types/data_stream.dart';
import 'message.dart';
import 'message_receiver.dart';
import 'message_sender.dart';

/// Sends text messages to the agent and emits a loopback message so the UI
/// can reflect the user's input immediately.
class TextMessageSender implements MessageSender, MessageReceiver {
  TextMessageSender({
    required Room room,
    this.topic = 'lk.chat',
  }) : _room = room {
    _controller = StreamController<ReceivedMessage>.broadcast();
  }

  final Room _room;
  final String topic;
  late final StreamController<ReceivedMessage> _controller;

  @override
  Stream<ReceivedMessage> messages() => _controller.stream;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<void> send(SentMessage message) async {
    final content = message.content;
    if (content is! SentUserInput) {
      return;
    }

    final LocalParticipant? localParticipant = _room.localParticipant;
    if (localParticipant == null) {
      throw StateError('Cannot send a message before connecting to the room.');
    }

    await localParticipant.sendText(
      content.text,
      options: SendTextOptions(topic: topic),
    );

    if (!_controller.isClosed) {
      _controller.add(
        ReceivedMessage(
          id: message.id,
          timestamp: message.timestamp,
          content: UserInput(content.text),
        ),
      );
    }
  }

  /// Convenience helper for sending text without constructing a [SentMessage].
  Future<void> sendText(String text) {
    final message = SentMessage(
      id: const Uuid().v4(),
      timestamp: DateTime.timestamp(),
      content: SentUserInput(text),
    );
    return send(message);
  }
}
