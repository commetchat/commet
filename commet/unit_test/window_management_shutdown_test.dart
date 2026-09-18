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

/// A client that only needs to be closable: [ClientManager] subscribes to the
/// streams and asks for components when it is added.
class _FakeClient implements Client {
  final _directMessages = _FakeDirectMessages();

  bool closed = false;

  @override
  String get identifier => 'fake';

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
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'closing the app releases the clients and quits through the window manager exactly once',
    () async {
      final client = _FakeClient();
      final manager = ClientManager();
      manager.addClient(client);
      app.clientManager = manager;
      addTearDown(() => app.clientManager = null);

      final destroyCalls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (call) async {
          destroyCalls.add(call);
          // The window must only go away once the clients are released: closing
          // waits for a sync in flight, and a window that vanished first would
          // leave the close half done.
          if (call.method == 'destroy') {
            expect(client.closed, isTrue);
          }
          return null;
        },
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          const MethodChannel('window_manager'),
          null,
        ),
      );

      await WindowManagement.close();
      // The Linux runner re-enters the close through the delete event that
      // destroy() posts, so a second close must not run any of it again.
      await WindowManagement.close();

      expect(client.closed, isTrue);
      expect(
        destroyCalls.where((call) => call.method == 'destroy'),
        hasLength(1),
      );
    },
  );
}
