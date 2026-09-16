// Downloads a sound's file from the homeserver for playback, never more than
// SoundboardConstraints.maxFileBytes (see soundboard_media_limits.dart).
import 'dart:typed_data';

import 'package:commet/client/components/soundboard/soundboard_constraints.dart';
import 'package:commet/client/components/soundboard/soundboard_media_limits.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart' as matrix;

/// Same request as the SDK's `getContent`, which reads the whole body before
/// anyone can look at its size.
Future<Uint8List> downloadSoundboardMedia(matrix.Client client, Uri mxc) async {
  if (mxc.scheme != 'mxc' || mxc.pathSegments.isEmpty) {
    throw SoundboardMediaRejected('not an mxc:// URI: $mxc');
  }
  final server = Uri.encodeComponent(mxc.authority);
  final mediaId = Uri.encodeComponent(mxc.pathSegments.first);

  final authenticated = await client.authenticatedMediaSupported();
  final path = authenticated
      ? '_matrix/client/v1/media/download/$server/$mediaId'
      : '_matrix/media/v3/download/$server/$mediaId';
  final request =
      http.Request('GET', client.baseUri!.resolveUri(Uri(path: path)));
  if (authenticated) {
    request.headers['authorization'] = 'Bearer ${client.bearerToken!}';
  }

  return fetchCapped(client.httpClient, request,
      maxBytes: SoundboardConstraints.maxFileBytes);
}
