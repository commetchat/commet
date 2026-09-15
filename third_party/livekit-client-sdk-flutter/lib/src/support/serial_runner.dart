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

/// Serializes async operations so concurrent calls execute sequentially.
///
/// When [run] is called while a previous operation is still in progress,
/// the new call waits for the previous one to complete before executing.
/// This prevents race conditions from concurrent calls to the same
/// async operation.
///
/// Equivalent to the Swift SDK's `SerialRunnerActor`.
class SerialRunner<T> {
  Future<void>? _pending;

  /// Whether an operation is currently in progress.
  bool get isRunning => _pending != null;

  /// Runs [block] after any pending operation completes.
  ///
  /// If no operation is pending, [block] executes immediately.
  /// If an operation is pending, waits for it to finish first.
  /// Errors from [block] propagate to the caller only, not to
  /// subsequent waiters.
  Future<T> run(Future<T> Function() block) async {
    while (_pending != null) {
      await _pending;
    }

    final completer = Completer<void>();
    _pending = completer.future;
    try {
      return await block();
    } finally {
      completer.complete();
      _pending = null;
    }
  }
}
