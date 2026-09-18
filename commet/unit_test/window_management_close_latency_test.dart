import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/main.dart' as app;
import 'package:commet/utils/notifying_list.dart';
import 'package:commet/utils/stored_stream_controller.dart';
import 'package:commet/utils/window_management.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDirectMessages implements DirectMessagesComponent {
  @override
  final INotifyingList<Room> directMessageRooms = NotifyingList.empty(
    growable: true,
  );

  @override
  final INotifyingList<Room> highlightedRoomsList = NotifyingList.empty(
    growable: true,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A client whose close waits on the sync transaction in flight: exactly the
/// teardown that made the visible window linger for up to 5 s (issue #80).
class _SlowClient implements Client {
  final _directMessages = _FakeDirectMessages();
  final _closeGate = Completer<void>();

  bool closed = false;
  bool closeStarted = false;

  void finishClosing() {
    closed = true;
    _closeGate.complete();
  }

  @override
  String get identifier => 'slow';

  @override
  NotifyingList<Room> get rooms => NotifyingList.empty(growable: true);

  @override
  List<Space> get spaces => [];

  @override
  Stream<Room> get onRoomAdded => const Stream.empty();

  @override
  Stream<Room> get onRoomRemoved => const Stream.empty();

  @override
  Stream<Space> get onSpaceAdded => const Stream.empty();

  @override
  Stream<Space> get onSpaceRemoved => const Stream.empty();

  @override
  Stream<void> get onSync => const Stream.empty();

  @override
  StoredStreamController<ClientConnectionStatusUpdate>
      get connectionStatusChanged => StoredStreamController();

  @override
  T? getComponent<T extends Component>() {
    final component = _directMessages;
    if (component is T) return component as T;
    return null;
  }

  @override
  Future<void> close({bool closeDatabase = true}) async {
    closeStarted = true;
    await _closeGate.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the window leaves the screen before the clients finish closing',
    () async {
      final client = _SlowClient();
      final manager = ClientManager();
      manager.addClient(client);
      app.clientManager = manager;
      addTearDown(() => app.clientManager = null);

      final calls = <String>[];
      bool? closedWhenDestroyed;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (call) async {
          calls.add(call.method);
          if (call.method == 'destroy') {
            closedWhenDestroyed = client.closed;
          }
          if (call.method == 'isMinimized') return false;
          return null;
        },
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          const MethodChannel('window_manager'),
          null,
        ),
      );

      final quitting = WindowManagement.close();
      await pumpEventQueue();

      expect(
        client.closeStarted,
        isTrue,
        reason: 'the teardown is the step that can take the full 5 s budget',
      );
      expect(
        calls,
        contains('hide'),
        reason: 'the window must be off the screen before the teardown starts',
      );
      expect(
        calls,
        isNot(contains('destroy')),
        reason: 'destroy still waits for the clients to be released',
      );

      client.finishClosing();
      await quitting;

      expect(calls, contains('destroy'));
      expect(
        closedWhenDestroyed,
        isTrue,
        reason: 'the clients are released before the window goes away',
      );
    },
  );
}
