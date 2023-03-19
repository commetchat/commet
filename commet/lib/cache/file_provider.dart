import 'dart:typed_data';

abstract class FileProvider {
  Future<Uri> resolve();

  late String fileIdentifier;
}
