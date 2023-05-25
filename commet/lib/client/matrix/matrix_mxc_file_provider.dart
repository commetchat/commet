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
  Future<Uri?> resolve() async {
    if (await fileCache.hasFile(fileIdentifier)) {
      var result = await fileCache.getFile(fileIdentifier);
      if (result != null) return result;
    }

    Uint8List? bytes;

    if (event != null) {
      var file = await event!.downloadAndDecryptAttachment();
      bytes = file.bytes;
    } else {
      var response = await client.httpClient.get(uri.getDownloadLink(client));
      if (response.statusCode == 200) {
        bytes = response.bodyBytes;
      }
    }

    if (bytes != null) {
      return fileCache.putFile(fileIdentifier, bytes);
    }

    return null;
  }
}
