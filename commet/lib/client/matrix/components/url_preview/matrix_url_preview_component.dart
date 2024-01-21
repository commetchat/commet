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
        proxyServerUrl: Uri.https(preferences.gifProxyUrl),
        publicKeyPem: """-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsHm6BWsALNS8QRGX19w7
60wzxtWOFDJKU2ygrUksDZBNjfErUSEnlyfthGlkDbXLj5jCw350iCPEBL02fdAM
i1vt6Q9o8l0KlUW+5ZkPdxPqS2P+fzdD0XZyTTSHKXOsxxW6BoTyetkjXjyQcUke
81QCBZHbrBrDddzjZanxKtThDTs452lOhdSG/od0y3/8I7YMZ8vRroPTp0DXSf7Y
VMVsGrhN5j+UnsZ9MFTRlsc/n/4MuP3TomyqxFc3XLJaqgCLjnuXbuIZ2bVAbODv
Ba0WQx4DI7vg9aQc7l1KHMJsZlkZ7yiKolxYKURdHTF1QgtVO0N/xwA9SPIHkGPJ
BwIDAQAB
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

    var response = await client.request(
        matrix.RequestType.GET, "/media/v3/preview_url",
        query: {"url": proxyUrl.toString()});

    var encryptedKey = response['og:commet:content_key'] as String;
    var key = privatePreviewGetter!.decryptContentKeyB64(encryptedKey);

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
        var decrypted = privatePreviewGetter!.decryptContentImage(bytes);

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
