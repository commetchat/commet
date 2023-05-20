import 'dart:io';
import 'dart:typed_data';
import 'package:commet/main.dart';
import 'package:matrix/matrix.dart';

import '../../utils/image/lod_image.dart';

class MatrixMxcImage extends LODImageProvider {
  Uri identifier;
  MatrixMxcImage(this.identifier, Client matrixClient,
      {String? blurhash,
      bool? doThumbnail,
      bool? doFullres,
      Event? matrixEvent})
      : super(
            blurhash: blurhash,
            loadThumbnail: (doThumbnail == null || doThumbnail == true)
                ? () =>
                    loadMatrixThumbnail(matrixClient, identifier, matrixEvent)
                : null,
            loadFullRes: (doFullres == null || doFullres == true)
                ? () => loadMatrixFullRes(matrixClient, identifier, matrixEvent)
                : null);

  static String getThumbnailIdentifier(Uri uri) {
    return "matrix_thumbnail-$uri";
  }

  static String getIdentifier(Uri uri) {
    return "matrix-$uri";
  }

  static Future<Uint8List?> loadMatrixThumbnail(
      Client client, Uri uri, Event? matrixEvent) async {
    var identifier = getThumbnailIdentifier(uri);

    if (await fileCache.hasFile(identifier)) {
      var cacheUri = await fileCache.getFile(identifier);

      if (cacheUri != null) {
        return File.fromUri(cacheUri).readAsBytes();
      }
    }

    Uint8List? bytes;
    if (matrixEvent != null) {
      var data =
          await matrixEvent.downloadAndDecryptAttachment(getThumbnail: true);
      bytes = data.bytes;
    } else {
      var response = await client.httpClient
          .get(uri.getThumbnail(client, width: 90, height: 90));
      if (response.statusCode == 200) {
        bytes = response.bodyBytes;
      }
    }

    if (bytes != null) {
      fileCache.putFile(identifier, bytes);
      return bytes;
    }

    return null;
  }

  static Future<Uint8List?> loadMatrixFullRes(
      Client client, Uri uri, Event? matrixEvent) async {
    var identifier = getIdentifier(uri);

    if (await fileCache.hasFile(identifier)) {
      var cacheUri = await fileCache.getFile(identifier);

      if (cacheUri != null) {
        return File.fromUri(cacheUri).readAsBytes();
      }
    }

    Uint8List? bytes;
    if (matrixEvent != null) {
      var data = await matrixEvent.downloadAndDecryptAttachment();
      bytes = data.bytes;
    } else {
      var response = await client.httpClient.get(uri.getDownloadLink(client));
      if (response.statusCode == 200) {
        bytes = response.bodyBytes;
      }
    }

    if (bytes != null) {
      fileCache.putFile(identifier, bytes);
      return bytes;
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
