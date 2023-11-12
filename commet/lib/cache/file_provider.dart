abstract class FileProvider {
  Future<Uri?> resolve();

  Future<void> save(String filepath);

  String get fileIdentifier;
}
