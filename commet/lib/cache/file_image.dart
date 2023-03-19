import 'dart:io';
import 'dart:ui';

import 'package:commet/cache/file_provider.dart';
import 'package:commet/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FileImageProvider extends ImageProvider<FileImageProvider> {
  final FileProvider file;
  final double scale;

  FileImageProvider(this.file, {this.scale = 1.0});

  @override
  Future<FileImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FileImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadBuffer(FileImageProvider key, DecoderBufferCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
    );
  }

  Future<Codec> _loadAsync(FileImageProvider key, DecoderBufferCallback decode) async {
    var path = await this.file.resolve();
    var file = File.fromUri(path);
    final Uint8List bytes = await file.readAsBytes();
    final ImmutableBuffer buffer = await ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  //the custom == and hashCode must be write, because the ImageProvider memory cache use it to identify the same image.
  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    bool res = other is FileImageProvider && other.file.fileIdentifier == file.fileIdentifier;
    return res;
  }

  @override
  int get hashCode => file.fileIdentifier.hashCode;

  @override
  String toString() => '${objectRuntimeType(this, 'FileImageProvider')}("${file.fileIdentifier}")';
}
