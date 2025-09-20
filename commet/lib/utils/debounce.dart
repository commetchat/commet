import 'dart:async';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  bool get running => _timer != null;

  Debouncer({required this.delay});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
