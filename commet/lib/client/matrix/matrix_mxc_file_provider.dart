import 'package:commet/cache/file_provider.dart';
import 'package:commet/main.dart';
import 'package:matrix/matrix.dart' as matrix;

class MxcFileProvider implements FileProvider {
  final Uri uri;
  final matrix.Client client;
  @override
  String get fileIdentifier => uri.toString();

  MxcFileProvider(this.client, this.uri);

  @override
  Future<Uri?> resolve() async {
    if (await fileCache.hasFile(fileIdentifier)) {
      var result = await fileCache.getFile(fileIdentifier);
      if (result != null) return result;
    }

    var response = await client.httpClient.get(uri.getDownloadLink(client));
    if (response.statusCode == 200) {
      var result = await fileCache.putFile(fileIdentifier, response.bodyBytes);
      return result;
    }

    return null;
  }
}
