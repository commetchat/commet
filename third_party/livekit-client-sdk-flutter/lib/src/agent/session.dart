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
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../core/room.dart';
import '../core/room_preconnect.dart';
import '../events.dart';
import '../logger.dart';
import '../managers/event.dart';
import '../participant/remote.dart';
import '../support/disposable.dart';
import '../token_source/jwt.dart';
import '../token_source/token_source.dart';
import '../types/other.dart';
import 'agent.dart';
import 'chat/message.dart';
import 'chat/message_receiver.dart';
import 'chat/message_sender.dart';
import 'chat/text_message_sender.dart';
import 'chat/transcription_stream_receiver.dart';
import 'room_agent.dart';
import 'session_options.dart';

/// A [Session] represents a connection to a LiveKit Room that can contain an agent.
///
/// A session encapsulates the lifecycle of connecting to a room, dispatching an
/// agent, and relaying messages between the user and the agent. It exposes
/// observable state such as the agent's connection status, any session errors,
/// and the ordered history of messages exchanged during the session.
///
/// To use a session, provide a token source (fixed or configurable) and call
/// [start]. When finished, call [end] to disconnect from the room. Messages can
/// be sent with [sendText], and the message history can be inspected or restored
/// via [messages], [getMessageHistory], and [restoreMessageHistory].
///
/// Message transport is pluggable: you can provide custom [MessageSender] and
/// [MessageReceiver] implementations to integrate with different channels. By
/// default, [Session] uses:
/// - [TextMessageSender] (topic `'lk.chat'`) to send user text and emit loopback
///   messages for immediate UI updates.
/// - [TranscriptionStreamReceiver] (topic `'lk.transcription'`) to receive agent
///   and user transcripts as a message stream.
///
/// The session is designed to be observed from Flutter widgets (it extends
/// [ChangeNotifier] through [DisposableChangeNotifier]) in the same way that the
/// Swift implementation conforms to `ObservableObject`.
class Session extends DisposableChangeNotifier {
  Session._({
    required _TokenSourceConfiguration tokenSourceConfiguration,
    required SessionOptions options,
    List<MessageSender>? senders,
    List<MessageReceiver>? receivers,
  })  : _tokenSourceConfiguration = tokenSourceConfiguration,
        _options = options,
        room = options.room {
    _agent.addListener(notifyListeners);

    final textMessageSender = TextMessageSender(room: room);
    final resolvedSenders = senders ?? <MessageSender>[textMessageSender];
    final resolvedReceivers =
        receivers ?? <MessageReceiver>[textMessageSender, TranscriptionStreamReceiver(room: room)];

    _senders.addAll(resolvedSenders);
    _receivers.addAll(resolvedReceivers);

    _observeRoom();
    _observeReceivers();

    onDispose(() async {
      _agent.removeListener(notifyListeners);
      await _roomListener?.dispose();
      await _cancelReceiverSubscriptions();
      await Future.wait(_receivers.toSet().map((receiver) => receiver.dispose()));
      _agentTimeoutTimer?.cancel();
    });
  }

  /// Initializes a new [Session] with a fixed token source.
  factory Session.fromFixedTokenSource(
    TokenSourceFixed tokenSource, {
    SessionOptions? options,
    List<MessageSender>? senders,
    List<MessageReceiver>? receivers,
  }) {
    return Session._(
      tokenSourceConfiguration: _FixedTokenSourceConfiguration(tokenSource),
      options: options ?? SessionOptions(),
      senders: senders,
      receivers: receivers,
    );
  }

  /// Initializes a new [Session] with a configurable token source.
  factory Session.fromConfigurableTokenSource(
    TokenSourceConfigurable tokenSource, {
    TokenRequestOptions tokenOptions = const TokenRequestOptions(),
    SessionOptions? options,
    List<MessageSender>? senders,
    List<MessageReceiver>? receivers,
  }) {
    return Session._(
      tokenSourceConfiguration: _ConfigurableTokenSourceConfiguration(tokenSource, tokenOptions),
      options: options ?? SessionOptions(),
      senders: senders,
      receivers: receivers,
    );
  }

  /// Creates a new [Session] configured for a specific agent.
  factory Session.withAgent(
    String agentName, {
    String? agentMetadata,
    required TokenSourceConfigurable tokenSource,
    SessionOptions? options,
    List<MessageSender>? senders,
    List<MessageReceiver>? receivers,
  }) {
    return Session.fromConfigurableTokenSource(
      tokenSource,
      tokenOptions: TokenRequestOptions(
        agentName: agentName,
        agentMetadata: agentMetadata,
      ),
      options: options,
      senders: senders,
      receivers: receivers,
    );
  }

  static final Uuid _uuid = const Uuid();

  final Room room;
  final SessionOptions _options;
  final _TokenSourceConfiguration _tokenSourceConfiguration;

  final Agent _agent = Agent();
  Agent get agent => _agent;

  SessionError? get error => _error;
  SessionError? _error;

  ConnectionState get connectionState => _connectionState;
  ConnectionState _connectionState = ConnectionState.disconnected;

  bool get isConnected => switch (_connectionState) {
        ConnectionState.connecting || ConnectionState.connected || ConnectionState.reconnecting => true,
        ConnectionState.disconnected => false,
      };

  final LinkedHashMap<String, ReceivedMessage> _messages = LinkedHashMap();
  UnmodifiableListView<ReceivedMessage> _messagesView = UnmodifiableListView<ReceivedMessage>(const []);

  List<ReceivedMessage> get messages => _messagesView;

  final List<MessageSender> _senders = [];
  final List<MessageReceiver> _receivers = [];
  final List<StreamSubscription<ReceivedMessage>> _receiverSubscriptions = [];

  EventsListener<RoomEvent>? _roomListener;
  Timer? _agentTimeoutTimer;

  /// Starts the session by fetching credentials and connecting to the room.
  Future<void> start() async {
    if (room.connectionState != ConnectionState.disconnected) {
      logger.info('Session.start() ignored: room already connecting or connected.');
      return;
    }

    _setError(null);
    _agentTimeoutTimer?.cancel();

    final Duration timeout = _options.agentConnectTimeout;

    Future<bool> connect() async {
      final response = await _tokenSourceConfiguration.fetch();
      await room.connect(
        response.serverUrl,
        response.participantToken,
      );
      return response.dispatchesAgent();
    }

    try {
      final bool dispatchesAgent;
      if (_options.preConnectAudio) {
        dispatchesAgent = await room.withPreConnectAudio(
          () async {
            _setConnectionState(ConnectionState.connecting);
            _agent.connecting(buffering: true);
            return connect();
          },
          timeout: timeout,
        );
      } else {
        _setConnectionState(ConnectionState.connecting);
        _agent.connecting(buffering: false);
        dispatchesAgent = await connect();
        await room.localParticipant?.setMicrophoneEnabled(true);
      }

      if (dispatchesAgent) {
        _agentTimeoutTimer = Timer(timeout, () {
          if (isConnected && !_agent.isConnected) {
            _agent.failed(AgentFailure.timeout);
          }
        });
      } else {
        _agentTimeoutTimer?.cancel();
        _agentTimeoutTimer = null;
      }
    } catch (error, stackTrace) {
      logger.warning('Session.start() failed: $error', error, stackTrace);
      _setError(SessionError.connection(error));
      _setConnectionState(ConnectionState.disconnected);
      _agent.disconnected();
    }
  }

  /// Terminates the session and disconnects from the room.
  Future<void> end() async {
    await room.disconnect();
  }

  /// Clears the last error.
  void dismissError() {
    _setError(null);
  }

  /// Sends a text message to the agent.
  ///
  /// Returns the [SentMessage] if the message was sent by all senders, or
  /// `null` if a sender failed. When a sender fails, the session error is set
  /// to [SessionErrorKind.sender].
  Future<SentMessage?> sendText(String text) async {
    final message = SentMessage(
      id: _uuid.v4(),
      timestamp: DateTime.timestamp(),
      content: SentUserInput(text),
    );

    try {
      for (final sender in _senders) {
        await sender.send(message);
      }
      return message;
    } catch (error, stackTrace) {
      logger.warning('Session.sendText() failed: $error', error, stackTrace);
      _setError(SessionError.sender(error));
      return null;
    }
  }

  /// Returns the message history.
  List<ReceivedMessage> getMessageHistory() => List.unmodifiable(_messages.values);

  /// Restores the message history with the provided [messages].
  void restoreMessageHistory(List<ReceivedMessage> messages) {
    _messages
      ..clear()
      ..addEntries(
        messages.sorted((a, b) => a.timestamp.compareTo(b.timestamp)).map(
              (message) => MapEntry(message.id, message),
            ),
      );
    _updateMessagesView();
    notifyListeners();
  }

  void _observeRoom() {
    final listener = room.createListener();
    listener.listen((event) async {
      _handleRoomEvent(event);
    });
    _roomListener = listener;
  }

  void _observeReceivers() {
    for (final receiver in _receivers) {
      final subscription = receiver.messages().listen(
        (message) {
          final existing = _messages[message.id];
          final shouldNotify = existing != message;
          _messages[message.id] = message;
          if (shouldNotify) {
            _updateMessagesView();
            notifyListeners();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          logger.warning('Session receiver error: $error', error, stackTrace);
          _setError(SessionError.receiver(error));
        },
      );
      _receiverSubscriptions.add(subscription);
    }
  }

  void _updateMessagesView() {
    _messagesView = UnmodifiableListView(_messages.values.toList(growable: false));
  }

  Future<void> _cancelReceiverSubscriptions() async {
    for (final subscription in _receiverSubscriptions) {
      await subscription.cancel();
    }
    _receiverSubscriptions.clear();
  }

  void _handleRoomEvent(RoomEvent event) {
    bool shouldUpdateAgent = false;

    if (event is RoomConnectedEvent || event is RoomReconnectedEvent) {
      _setConnectionState(ConnectionState.connected);
      shouldUpdateAgent = true;
    } else if (event is RoomReconnectingEvent) {
      _setConnectionState(ConnectionState.reconnecting);
      shouldUpdateAgent = true;
    } else if (event is RoomDisconnectedEvent) {
      _setConnectionState(ConnectionState.disconnected);
      _agent.disconnected();
      shouldUpdateAgent = true;
    }

    if (event is ParticipantEvent) {
      shouldUpdateAgent = true;
    }

    if (shouldUpdateAgent) {
      _updateAgent();
    }
  }

  void _updateAgent() {
    final connectionState = room.connectionState;
    _setConnectionState(connectionState);

    if (connectionState == ConnectionState.disconnected) {
      _agent.disconnected();
      return;
    }

    final RemoteParticipant? firstAgent = room.agentParticipants.firstOrNull;
    if (firstAgent != null) {
      _agent.connected(firstAgent);
    } else if (_agent.isConnected) {
      _agent.failed(AgentFailure.left);
    } else {
      _agent.connecting(buffering: _options.preConnectAudio);
    }
  }

  void _setConnectionState(ConnectionState state) {
    if (_connectionState == state) {
      return;
    }
    _connectionState = state;
    notifyListeners();
  }

  void _setError(SessionError? newError) {
    if (_error == newError) {
      return;
    }
    _error = newError;
    notifyListeners();
  }
}

enum SessionErrorKind {
  connection,
  sender,
  receiver,
}

/// Represents an error that occurred during a [Session].
class SessionError {
  SessionError._(this.kind, this.cause);

  final SessionErrorKind kind;
  final Object cause;

  String get message => switch (kind) {
        SessionErrorKind.connection => 'Connection failed: ${cause}',
        SessionErrorKind.sender => 'Message sender failed: ${cause}',
        SessionErrorKind.receiver => 'Message receiver failed: ${cause}',
      };

  static SessionError connection(Object cause) => SessionError._(SessionErrorKind.connection, cause);

  static SessionError sender(Object cause) => SessionError._(SessionErrorKind.sender, cause);

  static SessionError receiver(Object cause) => SessionError._(SessionErrorKind.receiver, cause);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionError && other.kind == kind && other.cause == cause;
  }

  @override
  int get hashCode => Object.hash(kind, cause);
}

sealed class _TokenSourceConfiguration {
  const _TokenSourceConfiguration();

  Future<TokenSourceResponse> fetch();
}

class _FixedTokenSourceConfiguration extends _TokenSourceConfiguration {
  const _FixedTokenSourceConfiguration(this.source);

  final TokenSourceFixed source;

  @override
  Future<TokenSourceResponse> fetch() => source.fetch();
}

class _ConfigurableTokenSourceConfiguration extends _TokenSourceConfiguration {
  const _ConfigurableTokenSourceConfiguration(this.source, this.options);

  final TokenSourceConfigurable source;
  final TokenRequestOptions options;

  @override
  Future<TokenSourceResponse> fetch() => source.fetch(options);
}
