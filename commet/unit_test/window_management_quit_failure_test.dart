import 'package:commet/utils/window_management.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a quit that fails is not latched: closing the window can be retried',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <String>[];
      var destroyAttempts = 0;
      var failNextDestroy = true;
      messenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (call) async {
          calls.add(call.method);
          if (call.method == 'isMinimized') return false;
          if (call.method != 'destroy') return null;

          destroyAttempts++;
          if (failNextDestroy) {
            failNextDestroy = false;
            throw PlatformException(code: 'destroy-failed');
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

      // The failed quit must not close the door behind it: with the clients
      // already closed and the window still up, nothing else could quit the app.
      await WindowManagement.close();
      expect(destroyAttempts, 1);
      expect(calls, contains('hide'));
      expect(
        calls.indexOf('show'),
        greaterThan(calls.indexOf('destroy')),
        reason: 'a failed quit must undo the hide, or the retry has no window',
      );

      await WindowManagement.close();
      expect(destroyAttempts, 2);
      expect(
        calls.where((method) => method == 'show'),
        hasLength(1),
        reason: 'the second quit succeeds and has nothing to restore',
      );
    },
  );
}
