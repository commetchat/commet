import 'dart:async';

extension StreamUtils<T> on Stream<T> {
  Future<T> nextItemAsFuture() {
    Completer<T> completer = Completer();

    listen(
      (event) {
        completer.complete(event);
      },
    );

    return completer.future;
  }
}
