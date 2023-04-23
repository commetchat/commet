abstract class FileProvider {
  Future<Uri> resolve();

  late String fileIdentifier;
}
