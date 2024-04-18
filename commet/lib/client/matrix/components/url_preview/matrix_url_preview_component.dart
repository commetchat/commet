import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:encrypted_url_preview/encrypted_url_preview.dart';

class MatrixUrlPreviewComponent implements UrlPreviewComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixUrlPreviewComponent(this.client);

  Map<String, UrlPreviewData> cache = {};

  EncryptedUrlPreview? privatePreviewGetter;

  void createPrivatePreviewGetter() {
    privatePreviewGetter = EncryptedUrlPreview(
        proxyServerUrl: Uri.https("telescope.commet.chat"),
        publicKeyPem: """-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAz+sAi8PsT4QwjV/+xXK0
vwavZJEjkwJyFODGWkoo7qB87Y2yU6/C4csul6kQpxBFu9ID7mCavAlr93/c70Qm
sgX791W7oOSpvyeffJe5iluzaglZ/KWYo6Bc0QajKT8rLdI5vUljVMyx/nR9rIhY
PvSJhSFLC2ZyUhhTb/ZeLm0arEtGeyfo1V3nLGsJZJx12UK8E0FpKP14S7Wke9zM
e05PDCU/llEQpUgQOJI9Vnji71Fgocii76aSULhXalGjQIzBGKib5MIYlb0Zgf8k
wKkRg6IrNt5kjad4PoRKocxj3ylvuxEtMN582ni3lO4gi1uzzVvFtJBzrhNMjTPC
pQIDAQAB
-----END PUBLIC KEY-----""");
  }

  @override
  Future<UrlPreviewData?> getPreview(Room room, TimelineEvent event) async {
    if (room.isE2EE && preferences.urlPreviewInE2EEChat == false) {
      Log.i(
          "Not getting url preview because chat is encrypted and its not enabled");
      return null;
    }

    var mxClient = (room as MatrixRoom).matrixRoom.client;

    var uri = event.links!.first;

    if (cache.containsKey(uri.toString())) {
      return cache[uri.toString()];
    }

    UrlPreviewData? data;

    if (room.isE2EE) {
      data = await getEncryptedPreviewData(mxClient, uri);
    } else {
      data = await fetchPreviewData(mxClient, uri);
    }

    cache[uri.toString()] = data!;
    return data;
  }

  @override
  UrlPreviewData? getCachedPreview(Room room, TimelineEvent event) {
    var uri = event.links!.first;
    if (cache.containsKey(uri.toString())) {
      return cache[uri.toString()];
    }

    return null;
  }

  Future<UrlPreviewData> getEncryptedPreviewData(
      matrix.Client client, Uri url) async {
    if (privatePreviewGetter == null) {
      createPrivatePreviewGetter();
    }

    var proxyUrl = privatePreviewGetter!.getProxyUrl(url);
    var key = privatePreviewGetter!.contentKey;

    var response = await client.request(
        matrix.RequestType.GET, "/media/v3/preview_url",
        query: {"url": proxyUrl.toString()});

    var title = response['og:title'] as String?;
    var siteName = response['og:site_name'] as String?;
    var imageUrl = response['og:image'] as String?;
    var description = response['og:description'] as String?;

    ImageProvider? image;

    if (imageUrl != null) {
      var mxcUri = Uri.parse(imageUrl);
      if (mxcUri.scheme == "mxc") {
        var response =
            await client.httpClient.get(mxcUri.getDownloadLink(client));

        var bytes = response.bodyBytes;
        var decrypted = privatePreviewGetter!.decryptContent(bytes, key);

        image = Image.memory(decrypted).image;
      }
    }

    if (title != null)
      title = privatePreviewGetter!.decryptContentString(title, key);
    if (siteName != null)
      siteName = privatePreviewGetter!.decryptContentString(siteName, key);

    if (description != null)
      description =
          privatePreviewGetter!.decryptContentString(description, key);

    return UrlPreviewData(url,
        siteName: siteName,
        title: title,
        description: description,
        image: image);
  }

  Future<UrlPreviewData?> fetchPreviewData(
      matrix.Client client, Uri url) async {
    var response = await client.request(
        matrix.RequestType.GET, "/media/v3/preview_url",
        query: {"url": url.toString()});

    var title = response['og:title'] as String?;
    var siteName = response['og:site_name'] as String?;
    var imageUrl = response['og:image'] as String?;
    var description = response['og:description'] as String?;
    ImageProvider? image;
    if (imageUrl != null) {
      var imageUri = Uri.parse(imageUrl);
      if (imageUri.scheme == "mxc") {
        image = MatrixMxcImage(imageUri, client);
      }
    }

    return UrlPreviewData(url,
        siteName: siteName,
        title: title,
        image: image,
        description: description);
  }
}
