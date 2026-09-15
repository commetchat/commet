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

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

import '../logger.dart' show logger;
import '../proto/livekit_models.pb.dart' as lk_models;

class BufferedDataPacket {
  final lk_models.DataPacket packet;
  final rtc.RTCDataChannelMessage message;
  final int sequence;

  BufferedDataPacket({
    required this.packet,
    required this.message,
    required this.sequence,
  });
}

class DataPacketBuffer {
  final List<BufferedDataPacket> _buffer = [];
  int _totalSize = 0;

  // Maximum buffer size in bytes (64MB by default)
  final int maxBufferSize;

  // Maximum number of packets (1000 by default)
  final int maxPacketCount;

  DataPacketBuffer({
    this.maxBufferSize = 64 * 1024 * 1024, // 64MB
    this.maxPacketCount = 1000,
  });

  void push(BufferedDataPacket item) {
    _buffer.add(item);
    _totalSize += item.message.binary.length;

    // Enforce buffer limits
    _enforceBufferLimits();
  }

  void _enforceBufferLimits() {
    int removedCount = 0;

    // Remove oldest packets if we exceed count limit
    while (_buffer.length > maxPacketCount && _buffer.isNotEmpty) {
      final removed = pop();
      if (removed == null) break;
      removedCount++;
    }

    // Remove oldest packets if we exceed size limit, but keep at least one packet
    while (_totalSize > maxBufferSize && _buffer.length > 1) {
      final removed = pop();
      if (removed == null) break;
      removedCount++;
    }

    // Log buffer limit enforcement
    if (removedCount > 0) {
      logger.warning('DataPacketBuffer limit reached: removed $removedCount old packets. '
          'Current: ${_buffer.length} packets, ${(_totalSize / 1024).round()}KB. '
          'Limits: $maxPacketCount packets, ${(maxBufferSize / 1024).round()}KB');
    }
  }

  BufferedDataPacket? pop() {
    if (_buffer.isEmpty) return null;
    final item = _buffer.removeAt(0);
    _totalSize -= item.message.binary.length;
    return item;
  }

  void popToSequence(int sequence) {
    while (_buffer.isNotEmpty && _buffer.first.sequence <= sequence) {
      pop();
    }
  }

  void alignBufferedAmount(int bufferedAmount) {
    // If bufferedAmount is 0, remove all packets
    if (bufferedAmount == 0) {
      clear();
      return;
    }

    while (_buffer.isNotEmpty) {
      final first = _buffer.first;
      final sizeAfterRemoving = _totalSize - first.message.binary.length;

      // If removing this packet would bring us <= bufferedAmount, stop
      if (sizeAfterRemoving <= bufferedAmount) {
        break;
      }

      pop();
    }
  }

  List<BufferedDataPacket> getAll() {
    return List.from(_buffer);
  }

  void clear() {
    _buffer.clear();
    _totalSize = 0;
  }

  int get length => _buffer.length;
  int get totalSize => _totalSize;
  bool get isEmpty => _buffer.isEmpty;
  bool get isNotEmpty => _buffer.isNotEmpty;

  // Buffer limit getters
  bool get isOverSizeLimit => _totalSize > maxBufferSize;
  bool get isOverCountLimit => _buffer.length > maxPacketCount;
  bool get isOverLimits => isOverSizeLimit || isOverCountLimit;

  // Buffer utilization (0.0 to 1.0+)
  double get sizeUtilization => _totalSize / maxBufferSize;
  double get countUtilization => _buffer.length / maxPacketCount;
}
