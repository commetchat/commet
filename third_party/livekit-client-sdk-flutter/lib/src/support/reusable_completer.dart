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

/// Manages a [Completer] lifecycle while exposing only its [Future].
///
/// Features:
/// - Safe completion (prevents double completion exceptions)
/// - Optional timeout handling
/// - Deterministic reset and disposal semantics
/// - Only exposes [Future], not the [Completer] itself
class ReusableCompleter<T> {
  Completer<T> _completer;
  Timer? _timeoutTimer;
  bool _isCompleted = false;
  bool _isDisposed = false;
  bool _hasPendingListener = false;

  /// Creates a new [ReusableCompleter] with an active completer.
  ReusableCompleter() : _completer = Completer<T>();

  /// The current future. Creates a new completer if the previous one finished.
  ///
  /// Throws [StateError] when called after [dispose].
  Future<T> get future {
    if (_isDisposed) {
      throw StateError('ReusableCompleter disposed');
    }
    if (_isCompleted) {
      _createCompleter();
    }
    _hasPendingListener = true;
    return _completer.future;
  }

  /// Whether the current completer has completed (with value or error).
  bool get isCompleted => _isCompleted;

  /// Whether the completer is still managing an active future.
  bool get isActive => !_isDisposed && !_isCompleted;

  /// Whether [dispose] has been called.
  bool get isDisposed => _isDisposed;

  /// Completes the current completer with the given [value].
  /// Returns `true` if successfully completed, otherwise `false`.
  bool complete([FutureOr<T>? value]) {
    if (_isDisposed || _isCompleted) {
      return false;
    }

    _completeCurrent((completer) => completer.complete(value));
    return true;
  }

  /// Completes the current completer with an [error].
  /// Returns `true` if successfully completed, otherwise `false`.
  bool completeError(Object error, [StackTrace? stackTrace]) {
    if (_isDisposed || _isCompleted) {
      return false;
    }

    _completeCurrent((completer) => completer.completeError(error, stackTrace));
    return true;
  }

  /// Sets up a timeout for the current completer.
  /// If not completed within [timeout], completes with a [TimeoutException].
  void setTimer(Duration timeout, {String? timeoutReason}) {
    if (_isDisposed || _isCompleted) {
      return;
    }

    _clearTimer();
    _timeoutTimer = Timer(timeout, () {
      if (_isDisposed || _isCompleted) {
        return;
      }
      final reason = timeoutReason ?? 'Operation timed out after $timeout';
      completeError(TimeoutException(reason, timeout));
    });
  }

  /// Resets the completer for reuse.
  ///
  /// Any pending future is completed with a [StateError] (or [error] if provided)
  /// before a new completer is created.
  void reset({Object? error, StackTrace? stackTrace}) {
    if (_isDisposed) {
      throw StateError('ReusableCompleter disposed');
    }

    if (!_isCompleted && _hasPendingListener) {
      _completeCurrent(
        (completer) => completer.completeError(
          error ?? StateError('ReusableCompleter reset'),
          stackTrace,
        ),
      );
    } else {
      _markCompletedWithoutNotify();
    }

    _createCompleter();
  }

  /// Disposes the completer, completing any pending future with an error.
  ///
  /// After disposal, the completer cannot be reused; calls to [future] throw
  /// [StateError] and completion methods return `false`.
  void dispose({Object? error, StackTrace? stackTrace}) {
    if (_isDisposed) {
      return;
    }

    if (!_isCompleted && _hasPendingListener) {
      _completeCurrent(
        (completer) => completer.completeError(
          error ?? StateError('ReusableCompleter disposed'),
          stackTrace,
        ),
      );
    } else {
      _markCompletedWithoutNotify();
    }

    _clearTimer();
    _isDisposed = true;
  }

  void _createCompleter() {
    _clearTimer();
    _completer = Completer<T>();
    _isCompleted = false;
    _hasPendingListener = false;
  }

  void _completeCurrent(
    void Function(Completer<T> completer) complete,
  ) {
    _isCompleted = true;
    _clearTimer();
    complete(_completer);
    _hasPendingListener = false;
  }

  void _markCompletedWithoutNotify() {
    _isCompleted = true;
    _clearTimer();
    _hasPendingListener = false;
  }

  void _clearTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }
}
