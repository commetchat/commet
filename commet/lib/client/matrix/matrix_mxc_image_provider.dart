import 'dart:io';
import 'dart:typed_data';
import 'package:commet/main.dart';
import 'package:commet/utils/mime.dart';
import 'package:matrix/matrix.dart';

import '../../utils/image/lod_image.dart';

class MatrixMxcImage extends LODImageProvider {
  Uri identifier;
  MatrixMxcImage(this.identifier, Client matrixClient,
      {String? blurhash,
      bool? doThumbnail,
      bool? doFullres,
      bool autoLoadFullRes = true,
      Event? matrixEvent})
      : super(
            blurhash: blurhash,
            loadThumbnail: (doThumbnail == null || doThumbnail == true)
                ? () =>
                    loadMatrixThumbnail(matrixClient, identifier, matrixEvent)
                : null,
            loadFullRes: (doFullres == null || doFullres == true)
                ? () => loadMatrixFullRes(matrixClient, identifier, matrixEvent)
                : null,
            autoLoadFullRes: autoLoadFullRes);

  static String getThumbnailIdentifier(Uri uri) {
    return "matrix_thumbnail-$uri";
  }

  static String getIdentifier(Uri uri) {
    return "matrix-$uri";
  }

  static Future<Uint8List?> loadMatrixThumbnail(
      Client client, Uri uri, Event? matrixEvent) async {
    var identifier = getThumbnailIdentifier(uri);

    if (await fileCache?.hasFile(identifier) == true) {
      var cacheUri = await fileCache?.getFile(identifier);

      if (cacheUri != null) {
        return File.fromUri(cacheUri).readAsBytes();
      }
    }

    Uint8List? bytes;
    if (matrixEvent != null) {
      var data =
          await matrixEvent.downloadAndDecryptAttachment(getThumbnail: true);
      if (Mime.imageTypes.contains(data.mimeType)) {
        bytes = data.bytes;
      }
    } else {
      var response = await client.httpClient
          .get(uri.getThumbnail(client, width: 90, height: 90));
      if (response.statusCode == 200) {
        bytes = response.bodyBytes;
      }
    }

    if (bytes != null) {
      fileCache?.putFile(identifier, bytes);
      return bytes;
    }

    return null;
  }

  static Future<Uint8List?> loadMatrixFullRes(
      Client client, Uri uri, Event? matrixEvent) async {
    var identifier = getIdentifier(uri);

    if (await fileCache?.hasFile(identifier) == true) {
      var cacheUri = await fileCache?.getFile(identifier);

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
      fileCache?.putFile(identifier, bytes);
      return bytes;
    }

    return null;
  }

  @override
  Future<bool> hasCachedFullres() async {
    var id = getIdentifier(identifier);
    return await fileCache?.hasFile(id) == true;
  }

  @override
  Future<bool> hasCachedThumbnail() async {
    var id = getThumbnailIdentifier(identifier);
    return await fileCache?.hasFile(id) == true;
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
