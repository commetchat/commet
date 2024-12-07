import 'dart:io';
import 'dart:typed_data';
import 'package:commet/cache/app_data.dart';
import 'package:commet/client/matrix/extensions/matrix_client_extensions.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/mime.dart';
import 'package:matrix/matrix.dart';

import '../../utils/image/lod_image.dart';

class MatrixMxcImage extends LODImageProvider {
  Uri identifier;
  MatrixMxcImage(this.identifier, Client matrixClient,
      {String? blurhash,
      bool? doThumbnail,
      bool? doFullres,
      bool cache = true,
      bool autoLoadFullRes = true,
      Event? matrixEvent})
      : super(
            blurhash: blurhash,
            loadThumbnail: (doThumbnail == null || doThumbnail == true)
                ? () => loadMatrixThumbnail(
                    matrixClient, identifier, matrixEvent, cache: cache)
                : null,
            loadFullRes: (doFullres == null || doFullres == true)
                ? () => loadMatrixFullRes(matrixClient, identifier, matrixEvent,
                    cache: cache)
                : null,
            autoLoadFullRes: autoLoadFullRes);

  static String getThumbnailIdentifier(Uri uri) {
    return "matrix_thumbnail-$uri";
  }

  static String getIdentifier(Uri uri) {
    return "matrix-$uri";
  }

  static Future<Uint8List?> loadMatrixThumbnail(
      Client client, Uri uri, Event? matrixEvent,
      {bool cache = false}) async {
    var identifier = getThumbnailIdentifier(uri);

    if (await AppData.instance.fileCache?.hasFile(identifier) == true) {
      var cacheUri = await AppData.instance.fileCache?.getFile(identifier);

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
      try {
        var response = await client.getContentThumbnailFromUri(uri, 90, 90);
        bytes = response.data;
      } catch (e, t) {
        Log.onError(e, t, content: "Failed to get content thumbnail");
      }
    }

    if (bytes != null && cache) {
      AppData.instance.fileCache?.putFile(identifier, bytes);
      return bytes;
    }

    return null;
  }

  static Future<Uint8List?> loadMatrixFullRes(
      Client client, Uri uri, Event? matrixEvent,
      {bool cache = true}) async {
    var identifier = getIdentifier(uri);

    if (await AppData.instance.fileCache?.hasFile(identifier) == true) {
      var cacheUri = await AppData.instance.fileCache?.getFile(identifier);

      if (cacheUri != null) {
        return File.fromUri(cacheUri).readAsBytes();
      }
    }

    Uint8List? bytes;
    if (matrixEvent != null) {
      var data = await matrixEvent.downloadAndDecryptAttachment();

      bytes = data.bytes;
    } else {
      try {
        var response = await client.getContentFromUri(uri);
        bytes = response.data;
      } catch (e, t) {
        Log.onError(e, t, content: "Failed to get content");
      }
    }

    if (bytes != null && cache) {
      AppData.instance.fileCache?.putFile(identifier, bytes);
      return bytes;
    }

    return null;
  }

  @override
  Future<bool> hasCachedFullres() async {
    var id = getIdentifier(identifier);
    return await AppData.instance.fileCache?.hasFile(id) == true;
  }

  @override
  Future<bool> hasCachedThumbnail() async {
    var id = getThumbnailIdentifier(identifier);
    return await AppData.instance.fileCache?.hasFile(id) == true;
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
