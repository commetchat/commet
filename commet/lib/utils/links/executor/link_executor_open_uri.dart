import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/links/executor/link_executor.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkExecutorOpenUri extends LinkExecutor {
  LinkExecutorOpenUri(super.platforms, super.data);

  @override
  String getDescription(Uri uri) {
    return "Open the url with the app registered on your system? \n\n `\n${getTransformedUri(uri)}\n`";
  }

  String procComponent(String component) {
    return Uri.encodeComponent(Uri.decodeComponent(component));
  }

  Uri getTransformedUri(Uri uri) {
    String result = data["uri"];

    // Uri Encode all components, to protect against weird url escapes: `https://example.com; rm -rf ~`
    var processed = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.port,
        queryParameters: uri.queryParameters.isEmpty
            ? null
            : Map.fromEntries(uri.queryParameters.entries.map(
                (i) => MapEntry(procComponent(i.key), procComponent(i.value)))),
        pathSegments: uri.pathSegments.isEmpty
            ? null
            : uri.pathSegments.map((i) => procComponent(i)).toList(),
        fragment: uri.fragment.isEmpty ? null : procComponent(uri.fragment));

    result = result.replaceAll("\${uri}", processed.toString());

    return Uri.parse(result);
  }

  @override
  Future<bool> canHandleLink(Uri uri) async {
    if (await super.canHandleLink(uri) == false) return false;

    var xformed = getTransformedUri(uri);

    if (PlatformUtils.isLinux || PlatformUtils.isWindows) {
      var canLaunchXformed = await canLaunchUrl(xformed);
      Log.i("Can launch: ${canLaunchXformed}");

      return canLaunchXformed;
    }

    return true;
  }

  @override
  Future<void> execute(Uri uri) async {
    var xformed = getTransformedUri(uri);
    Log.i("Launching url: $xformed");
    Log.i("Can launch: ${await canLaunchUrl(xformed)}");
    var result = await launchUrl(xformed, mode: LaunchMode.externalApplication);
    Log.i("Result: $result");
  }
}
