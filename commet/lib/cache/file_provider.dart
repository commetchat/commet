abstract class FileProvider {
  Future<Uri?> resolve();

  String get fileIdentifier;
}
