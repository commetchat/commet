import 'dart:io';
import 'dart:typed_data';
import 'package:commet/main.dart';
import 'package:matrix/matrix.dart';

import '../../utils/image/lod_image.dart';

class MatrixMxcImage extends LODImageProvider {
  Uri identifier;
  MatrixMxcImage(this.identifier, Client matrixClient,
      {String? blurhash, bool? doThumbnail, bool? doFullres})
      : super(
            blurhash: blurhash,
            loadThumbnail: (doThumbnail == null || doThumbnail == true)
                ? () => loadMatrixThumbnail(matrixClient, identifier)
                : null,
            loadFullRes: (doFullres == null || doFullres == true)
                ? () => loadMatrixFullRes(matrixClient, identifier)
                : null);

  static String getThumbnailIdentifier(Uri uri) {
    return "matrix_thumbnail-$uri";
  }

  static String getIdentifier(Uri uri) {
    return "matrix-$uri";
  }

  static Future<Uint8List?> loadMatrixThumbnail(Client client, Uri uri) async {
    var identifier = getThumbnailIdentifier(uri);

    if (await fileCache.hasFile(identifier)) {
      var cacheUri = await fileCache.getFile(identifier);

      if (cacheUri != null) {
        return File.fromUri(cacheUri).readAsBytes();
      }
    }

    var response = await client.httpClient
        .get(uri.getThumbnail(client, width: 90, height: 90));

    if (response.statusCode == 200) {
      fileCache.putFile(identifier, response.bodyBytes);
      return response.bodyBytes;
    }

    return null;
  }

  static Future<Uint8List?> loadMatrixFullRes(Client client, Uri uri) async {
    var identifier = getIdentifier(uri);

    if (await fileCache.hasFile(identifier)) {
      var cacheUri = await fileCache.getFile(identifier);

      if (cacheUri != null) {
        return File.fromUri(cacheUri).readAsBytes();
      }
    }

    var response = await client.httpClient.get(uri.getDownloadLink(client));

    if (response.statusCode == 200) {
      fileCache.putFile(identifier, response.bodyBytes);
      return response.bodyBytes;
    }

    return null;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    bool res = other is MatrixMxcImage && other.identifier == identifier;
    return res;
  }

  @override
  int get hashCode => identifier.hashCode;
}
