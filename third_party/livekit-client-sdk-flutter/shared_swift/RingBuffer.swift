/*
 * Copyright 2025 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

// Simple ring-buffer used for internal audio processing. Not thread-safe.
class RingBuffer<T: Numeric> {
    private var _isFull = false
    private var _buffer: [T]
    private var _head: Int = 0

    init(size: Int) {
        _buffer = [T](repeating: 0, count: size)
    }

    func write(_ value: T) {
        _buffer[_head] = value
        _head = (_head + 1) % _buffer.count
        if _head == 0 { _isFull = true }
    }

    func write(_ sequence: [T]) {
        for value in sequence {
            write(value)
        }
    }

    func read() -> [T]? {
        guard _isFull else { return nil }

        if _head == 0 {
            return _buffer // Return the entire buffer if _head is at the start
        } else {
            // Return the buffer in the correct order
            return Array(_buffer[_head ..< _buffer.count] + _buffer[0 ..< _head])
        }
    }
}
