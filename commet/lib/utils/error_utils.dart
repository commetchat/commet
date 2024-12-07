import 'package:commet/cache/error_log.dart';
import 'package:commet/config/build_config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ErrorUtils {
  static reportIssue(ErrorEntry entry) async {
    var data = await getErrorData(entry);
    var uri = Uri.https("github.com", "/commetchat/commet/issues/new", {
      "title": entry.detail.split("\n").first,
      "body": data,
      "labels": "bug",
    });

    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<String> getErrorData(ErrorEntry entry) async {
    var deviceInfo = await DeviceInfoPlugin().deviceInfo;
    return """
> [!NOTE]
> This issue has been automatically filled out by Commet's issue reporter

### Exception: 
${entry.detail}

<details open>
<summary>Stack Trace</summary>
<br>

```
${entry.stackTrace.toString()}
```
</details>

<details open>
<summary>Device Information</summary>
<br>

**Device**
Platform: `${BuildConfig.PLATFORM}`
Version: `${BuildConfig.VERSION_TAG}`
Git Hash: `${BuildConfig.GIT_HASH}`
Detail: `${BuildConfig.BUILD_DETAIL}`


**System Info**
${deviceInfo.data["name"] is String ? "Name: `${deviceInfo.data["name"]}`" : ""}
${deviceInfo.data["version"] is String ? "Version: `${deviceInfo.data["version"]}`" : ""}
${deviceInfo.data["product"] is String ? "Product: `${deviceInfo.data["product"]}`" : ""}
</details>
""";
  }
}
