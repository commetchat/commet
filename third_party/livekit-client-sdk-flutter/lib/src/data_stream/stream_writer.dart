import 'dart:async';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import '../core/engine.dart';
import '../proto/livekit_models.pb.dart' as lk_models;
import '../types/data_stream.dart';
import '../types/other.dart';
import '../utils.dart';

class BaseStreamWriter<T, InfoType extends BaseStreamInfo> {
  final StreamWriter<T> writableStream;
  Future<void> Function()? onClose;

  final InfoType info;

  BaseStreamWriter({required this.writableStream, required this.info, this.onClose});

  Future<void> write(T chunk) async {
    return writableStream.write(chunk);
  }

  Future<void> close() async {
    await writableStream.close();
    await onClose?.call();
  }
}

class TextStreamWriter extends BaseStreamWriter<String, TextStreamInfo> {
  TextStreamWriter({required super.writableStream, required super.info, required super.onClose});
}

class ByteStreamWriter extends BaseStreamWriter<Uint8List, ByteStreamInfo> {
  ByteStreamWriter({
    required super.writableStream,
    required super.info,
    required super.onClose,
  });
}

class WritableStream<T> implements StreamWriter<T> {
  String streamId;
  int chunkId = 0;
  List<String>? destinationIdentities;
  Engine engine;

  WritableStream({
    required this.streamId,
    required this.engine,
    this.destinationIdentities,
  });

  @override
  Future<void> close() async {
    final trailer = lk_models.DataStream_Trailer(
      streamId: streamId,
    );
    final trailerPacket = lk_models.DataPacket(
      kind: lk_models.DataPacket_Kind.RELIABLE,
      destinationIdentities: destinationIdentities,
      streamTrailer: trailer,
    );
    await engine.sendDataPacket(trailerPacket, reliability: Reliability.reliable);
  }

  @override
  Future<void> write(T chunk) async {
    for (final content in splitChunk(chunk, kStreamChunkSize)) {
      await engine.waitForBufferStatusLow(Reliability.reliable);
      final chunk = lk_models.DataStream_Chunk(
        content: content,
        streamId: streamId,
        chunkIndex: Int64(chunkId),
      );
      final chunkPacket = lk_models.DataPacket(
        kind: lk_models.DataPacket_Kind.RELIABLE,
        destinationIdentities: destinationIdentities,
        streamChunk: chunk,
      );
      await engine.sendDataPacket(chunkPacket, reliability: Reliability.reliable);
      chunkId += 1;
    }
  }

  List<Uint8List> splitChunk(T chunk, int chunkSize) {
    if (chunk is String) {
      return splitUtf8(chunk as String, chunkSize);
    } else if (chunk is Uint8List) {
      return splitUint8List(chunk as Uint8List, chunkSize);
    } else {
      throw Exception('Unsupported type: ${chunk.runtimeType}');
    }
  }

  List<Uint8List> splitUint8List(Uint8List bytes, int chunkSize) {
    final List<Uint8List> result = [];
    if (bytes.length <= chunkSize) {
      return [bytes];
    }
    // Split the Uint8List into chunks of the specified size
    while (bytes.length > chunkSize) {
      result.add(bytes.sublist(0, chunkSize));
      bytes = bytes.sublist(chunkSize);
    }
    if (bytes.isNotEmpty) {
      result.add(bytes);
    }
    return result;
  }
}
