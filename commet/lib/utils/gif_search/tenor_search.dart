import 'dart:convert';
import 'package:commet/main.dart';
import 'package:http/http.dart' as http;
import 'package:commet/utils/gif_search/gif_search_result.dart';

class TenorSearch {
  static Future<List<GifSearchResult>> search(String query) async {
    // The ui should never actually let the user search if this is disabled, so this *shouldn't* be neccessary
    // but just to be safe!
    if (!preferences.tenorGifSearchEnabled) return [];

    var uri = Uri.https(
        preferences.gifProxyUrl, "/proxy/tenor/api/v2/search", {"q": query});

    var result = await http.get(uri);
    if (result.statusCode == 200) {
      var data = jsonDecode(result.body) as Map<String, dynamic>;
      var results = data['results'] as List?;

      if (results != null) {
        return results.map((e) => parseTenorResult(e)).toList();
      }
    }

    return [];
  }

  static GifSearchResult parseTenorResult(Map<String, dynamic> result) {
    const int sizeLimit = 3000000; //3 MB

    var formats = result['media_formats'] as Map<String, dynamic>;

    var preview =
        formats['tinygif'] ?? formats['nanogif'] ?? formats['mediumgif'];

    //dynamic fullRes;

    var fullRes = formats['gif'];

    //We only want to send full res if less than 3mb
    if (fullRes['size'] as int > sizeLimit && formats['mediumgif'] != null) {
      fullRes = formats['mediumgif'];
    }

    List<dynamic> dimensions = fullRes['dims']! as List<dynamic>;

    return GifSearchResult(
        convertUrl(preview['url']),
        convertUrl(fullRes['url']),
        (dimensions[0] as int).roundToDouble(),
        (dimensions[1] as int).roundToDouble());
  }

  static Uri convertUrl(String url) {
    var uri = Uri.parse(url);

    var proxyUri =
        Uri.https("proxy.commet.chat", "/proxy/tenor/media${uri.path}");

    return proxyUri;
  }
}
