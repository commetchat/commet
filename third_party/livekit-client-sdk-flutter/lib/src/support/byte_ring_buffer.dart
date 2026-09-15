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

import 'dart:math' as math;
import 'dart:typed_data';

/// Fixed-size ring buffer optimized for PCM byte data.
///
/// Keeps the newest [capacity] bytes and discards the oldest as needed.
class ByteRingBuffer {
  ByteRingBuffer(this.capacity)
      : assert(capacity > 0),
        _buffer = Uint8List(capacity);

  final int capacity;
  final Uint8List _buffer;

  int _start = 0;
  int _length = 0;

  /// Number of bytes currently stored.
  int get length => _length;

  bool get isEmpty => _length == 0;

  /// Appends [data], overwriting the oldest samples when necessary.
  ///
  /// Returns `true` when any existing data was dropped.
  bool write(Uint8List data) {
    if (data.isEmpty) {
      return false;
    }

    // If the incoming chunk exceeds the buffer capacity, keep only the newest bytes.
    if (data.length >= capacity) {
      final keepStart = data.length - capacity;
      _buffer.setRange(0, capacity, data, keepStart);
      _start = 0;
      _length = capacity;
      return true;
    }

    final int freeSpace = capacity - _length;
    bool overflowed = false;

    if (data.length > freeSpace) {
      overflowed = true;
      final int drop = data.length - freeSpace;
      _start = (_start + drop) % capacity;
      _length = _length >= drop ? _length - drop : 0;
    }

    final int writeIndex = (_start + _length) % capacity;
    final int firstCopy = math.min(capacity - writeIndex, data.length);
    _buffer.setRange(writeIndex, writeIndex + firstCopy, data, 0);

    final int remaining = data.length - firstCopy;
    if (remaining > 0) {
      _buffer.setRange(0, remaining, data, firstCopy);
    }

    _length = math.min(capacity, _length + data.length);
    return overflowed;
  }

  /// Returns the buffered data in chronological order.
  Uint8List toBytes() {
    if (_length == 0) {
      return Uint8List(0);
    }

    final result = Uint8List(_length);
    final int firstCopy = math.min(capacity - _start, _length);
    result.setRange(0, firstCopy, _buffer, _start);

    final int remaining = _length - firstCopy;
    if (remaining > 0) {
      result.setRange(firstCopy, _length, _buffer, 0);
    }

    return result;
  }

  /// Returns buffered data and clears the buffer.
  Uint8List takeBytes() {
    final result = toBytes();
    clear();
    return result;
  }

  /// Resets the buffer to an empty state.
  void clear() {
    _start = 0;
    _length = 0;
  }
}
