import 'dart:io';
import 'dart:typed_data';
import 'package:commet/cache/file_provider.dart';
import 'package:commet/main.dart';
import 'package:matrix/matrix.dart' as matrix;

class MxcFileProvider implements FileProvider {
  final Uri uri;
  final matrix.Client client;
  final matrix.Event? event;
  @override
  String get fileIdentifier => uri.toString();

  MxcFileProvider(this.client, this.uri, {this.event});

  @override
  Future<Uri?> resolve({String? savePath}) async {
    var cached = await fileCache?.getFile(fileIdentifier);
    if (cached != null) {
      return cached;
    }

    var bytes = await getFileData();

    if (bytes == null) {
      return null;
    }

    return fileCache?.putFile(fileIdentifier, bytes);
  }

  @override
  Future<void> save(String filepath) async {
    var bytes = await getFileData();
    if (bytes == null) return;

    var file = File(filepath);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  Future<Uint8List?> getFileData() async {
    Uint8List? bytes;

    var cached = await fileCache?.getFile(fileIdentifier);
    if (cached != null) {
      return File.fromUri(cached).readAsBytes();
    }

    if (event != null) {
      var file = await event!.downloadAndDecryptAttachment();
      bytes = file.bytes;
    } else {
      var response = await client.httpClient.get(uri.getDownloadLink(client));
      if (response.statusCode == 200) {
        bytes = response.bodyBytes;
      }
    }

    return bytes;
  }
}
