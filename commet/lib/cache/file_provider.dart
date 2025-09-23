import 'dart:io';
import 'dart:typed_data';

class DownloadProgress {
  int downloaded;
  int total;

  DownloadProgress(this.downloaded, this.total);
}

abstract class FileProvider {
  Future<Uri?> resolve();

  Future<void> save(String filepath);

  Stream<DownloadProgress>? get onProgressChanged;

  Future<Uint8List?> getFileData();

  String get fileIdentifier;
}

class SystemFileProvider implements FileProvider {
  File file;

  @override
  String get fileIdentifier => file.path;

  @override
  Future<Uri?> resolve() async {
    return file.uri;
  }

  @override
  Future<void> save(String filepath) {
    throw UnimplementedError();
  }

  SystemFileProvider(this.file);

  @override
  Stream<DownloadProgress>? get onProgressChanged => null;

  @override
  Future<Uint8List?> getFileData() {
    return file.readAsBytes();
  }
}
