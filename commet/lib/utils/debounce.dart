import 'dart:async';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  bool get running => _timer != null;

  Debouncer({required this.delay});

  run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
