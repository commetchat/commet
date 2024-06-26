import 'dart:io';

abstract class FileProvider {
  Future<Uri?> resolve();

  Future<void> save(String filepath);

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
}
