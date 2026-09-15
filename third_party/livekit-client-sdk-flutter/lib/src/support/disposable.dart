// Copyright 2024 LiveKit, Inc.
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

import 'package:flutter/foundation.dart' show ChangeNotifier, VoidCallback;

import 'package:meta/meta.dart';

import '../extensions.dart';
import '../logger.dart';

typedef OnDisposeFunc = Future<void> Function();

mixin _Disposer {
  //
  final _disposeFuncs = <OnDisposeFunc>[];
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;
  int get disposeFuncCount => _disposeFuncs.length;

  // last added func will be called first when disposing
  void onDispose(OnDisposeFunc func) => _disposeFuncs.add(func);

  Future<bool> _dispose() async {
    if (!_isDisposed) {
      logger.finer('[${objectId}] dispose()');
      _isDisposed = true;
      if (_disposeFuncs.isNotEmpty) {
        logger.finer('[$objectId] running ${_disposeFuncs.length} dispose funcs...');
        // call dispose funcs in reverse order
        for (final disposeFunc in _disposeFuncs.reversed) {
          try {
            await disposeFunc();
          } catch (e, stack) {
            logger.warning('[$objectId] error during dispose: $e', e, stack);
          }
        }
        _disposeFuncs.clear();
        logger.finer('[$objectId] dispose complete.');
      }
      return true;
    } else {
      logger.warning('[$objectId] unnecessary dispose() called.');
      return false;
    }
  }
}

abstract class Disposable with _Disposer {
  @mustCallSuper
  Future<bool> dispose() async {
    return await _dispose();
  }
}

abstract class DisposableChangeNotifier extends ChangeNotifier with _Disposer {
  @override
  Future<bool> dispose() async {
    if (!isDisposed) super.dispose();
    return await super._dispose();
  }

  @override
  bool get hasListeners {
    if (isDisposed) {
      logger.warning('called hasListeners on a disposed ChangeNotifier');
      return false;
    }
    return super.hasListeners;
  }

  @override
  void addListener(VoidCallback listener) {
    if (isDisposed) {
      logger.warning('called addListener() on a disposed ChangeNotifier');
      return;
    }
    super.addListener(listener);
  }

  @override
  void notifyListeners() {
    if (isDisposed) {
      logger.warning('called notifyListeners() on a disposed ChangeNotifier');
      return;
    }
    super.notifyListeners();
  }

  @override
  void removeListener(VoidCallback listener) {
    if (isDisposed) {
      logger.warning('called removeListener() on a disposed ChangeNotifier');
      return;
    }
    super.removeListener(listener);
  }
}
