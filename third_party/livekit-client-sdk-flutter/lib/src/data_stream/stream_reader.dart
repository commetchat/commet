import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../proto/livekit_models.pb.dart' show DataStream_Chunk;
import '../types/data_stream.dart';
import 'errors.dart';

abstract class BaseStreamReader<T extends BaseStreamInfo, U> {
  DataStreamController<DataStream_Chunk>? reader;

  final num? _totalByteSize;

  T? _info;

  T? get info => _info;

  num _bytesReceived = 0;

  BaseStreamReader(T info, DataStreamController<DataStream_Chunk> stream, this._totalByteSize) {
    reader = stream;
    _info = info;
  }

  void handleChunkReceived(DataStream_Chunk chunk);

  Function(double? progress)? onProgress;

  Future<U> readAll();

  void validateBytesReceived([bool doneReceiving = false]) {
    if (_totalByteSize is! num || _totalByteSize == 0) {
      return;
    }

    if (doneReceiving && _bytesReceived < _totalByteSize) {
      throw DataStreamError(
        message:
            'Not enough chunk(s) received - expected $_totalByteSize bytes of data total, only received $_bytesReceived bytes',
        reason: DataStreamErrorReason.Incomplete,
      );
    } else if (_bytesReceived > _totalByteSize) {
      throw DataStreamError(
        message:
            'Extra chunk(s) received - expected $_totalByteSize bytes of data total, received $_bytesReceived bytes',
        reason: DataStreamErrorReason.LengthExceeded,
      );
    }
  }
}

class ByteStreamReader extends BaseStreamReader<ByteStreamInfo, List<Uint8List>> with Stream<DataStream_Chunk> {
  ByteStreamReader(super.info, super.stream, super.totalByteSize);

  @override
  void handleChunkReceived(DataStream_Chunk chunk) {
    _bytesReceived += chunk.content.length;

    validateBytesReceived();

    final currentProgress = _totalByteSize != null ? _bytesReceived / _totalByteSize : null;
    onProgress?.call(currentProgress);
  }

  @override
  Future<List<Uint8List>> readAll() async {
    final Set<Uint8List> chunks = {};
    await for (final chunk in this) {
      chunks.add(Uint8List.fromList(chunk.content));
    }
    return chunks.toList();
  }

  StreamSubscription<DataStream_Chunk>? _streamSubscription;
  @override
  StreamSubscription<DataStream_Chunk> listen(void Function(DataStream_Chunk event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    _streamSubscription ??= reader!.streamController.stream.listen((DataStream_Chunk data) {
      handleChunkReceived(data);
      onData?.call(data);
    }, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

    return _streamSubscription!;
  }
}

class TextStreamReader extends BaseStreamReader<TextStreamInfo, String> with Stream<DataStream_Chunk> {
  Map<num, DataStream_Chunk> receivedChunks = {};

  TextStreamReader(super.info, super.stream, super.totalChunkCount);

  @override
  void handleChunkReceived(DataStream_Chunk chunk) {
    final index = chunk.chunkIndex.toInt();
    final previousChunkAtIndex = receivedChunks[index];
    if (previousChunkAtIndex != null && previousChunkAtIndex.version > chunk.version) {
      // we have a newer version already, dropping the old one
      return;
    }
    receivedChunks[index] = chunk;
    _bytesReceived += chunk.content.length;

    validateBytesReceived();

    final currentProgress = _totalByteSize != null ? _bytesReceived / _totalByteSize : null;
    onProgress?.call(currentProgress);
  }

  @override
  Future<String> readAll() async {
    var finalString = '';
    await for (final chunk in this) {
      try {
        finalString += utf8.decode(chunk.content.toList());
      } catch (e) {
        throw DataStreamError(
          message: 'Failed to decode chunk data: $e',
          reason: DataStreamErrorReason.DecodeFailed,
        );
      }
    }
    return finalString;
  }

  StreamSubscription<DataStream_Chunk>? _streamSubscription;
  @override
  StreamSubscription<DataStream_Chunk> listen(void Function(DataStream_Chunk event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    _streamSubscription ??= reader!.streamController.stream.listen((DataStream_Chunk data) {
      handleChunkReceived(data);
      onData?.call(data);
    }, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

    return _streamSubscription!;
  }
}
