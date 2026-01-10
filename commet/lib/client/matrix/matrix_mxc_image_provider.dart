import 'dart:io';
import 'dart:typed_data';
import 'package:commet/client/matrix/extensions/matrix_client_extensions.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/mime.dart';
import 'package:matrix/matrix.dart';

import '../../utils/image/lod_image.dart';

class MatrixMxcImage extends LODImageProvider {
  Uri identifier;
  Client client;
  MatrixMxcImage(
    this.identifier,
    this.client, {
    super.blurhash,
    bool? doThumbnail,
    bool? doFullres,
    bool cache = true,
    super.autoLoadFullRes,
    super.thumbnailHeight,
    super.fullResHeight,
    Event? matrixEvent,
  }) : super(
          id: "$identifier-$doThumbnail-$doFullres-$thumbnailHeight-$fullResHeight",
          loadThumbnail: (doThumbnail == null || doThumbnail == true)
              ? () => retryUntilOnline<Uint8List?>(
                  client,
                  () => loadMatrixThumbnail(
                        client,
                        identifier,
                        matrixEvent,
                        cache: cache,
                      ))
              : null,
          loadFullRes: (doFullres == null || doFullres == true)
              ? () => retryUntilOnline<Uint8List?>(
                  client,
                  () => loadMatrixFullRes(
                        client,
                        identifier,
                        matrixEvent,
                        cache: cache,
                      ))
              : null,
        );

  static String getThumbnailIdentifier(Uri uri) {
    return "matrix_thumbnail-$uri";
  }

  static String getIdentifier(Uri uri) {
    return "matrix-$uri";
  }

  static Future<T> retryUntilOnline<T>(
      Client client, Future<T> callback()) async {
    try {
      var value = await callback();
      return value;
    } catch (error, trace) {
      if (error is SocketException) {
        while (true) {
          var result = await client.onSyncStatus.stream.first;

          if (result.status == SyncStatus.finished) {
            var result = await callback();
            return result;
          }
        }
      } else {
        Log.onError(error, trace);
        throw UnimplementedError();
      }
    }
  }

  static Future<Uint8List?> loadMatrixThumbnail(
    Client client,
    Uri uri,
    Event? matrixEvent, {
    bool cache = true,
  }) async {
    var identifier = getThumbnailIdentifier(uri);

    if (await fileCache?.hasFile(identifier) == true) {
      var cacheUri = await fileCache?.getFile(identifier);

      if (cacheUri != null) {
        return File.fromUri(cacheUri).readAsBytes();
      }
    }

    Uint8List? bytes;
    if (matrixEvent != null) {
      var data = await matrixEvent.downloadAndDecryptAttachment(
        getThumbnail: true,
      );

      String mime = matrixEvent.thumbnailMimetype;

      if (mime == "") {
        mime = Mime.lookupType("", data: data.bytes) ?? "";
      }

      if (Mime.imageTypes.contains(mime)) {
        bytes = data.bytes;
      } else {
        Log.w("Attachment thumbnail had unknown mime type: '${mime}'");
      }
    } else {
      var response = await client.getContentThumbnailFromUri(uri, 90, 90);
      bytes = response.data;
    }

    if (bytes != null && cache) {
      fileCache?.putFile(identifier, bytes);
      return bytes;
    }

    return null;
  }

  static Future<Uint8List?> loadMatrixFullRes(
    Client client,
    Uri uri,
    Event? matrixEvent, {
    bool cache = true,
  }) async {
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
      var response = await client.getContentFromUri(uri);
      bytes = response.data;
    }

    if (cache) {
      fileCache?.putFile(identifier, bytes);
      return bytes;
    }

    return null;
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
