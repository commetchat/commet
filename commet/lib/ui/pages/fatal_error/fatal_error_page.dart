import 'package:commet/config/build_config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class FatalErrorPage extends StatelessWidget {
  const FatalErrorPage(this.error, this.trace, {super.key});
  final Object error;
  final StackTrace trace;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Material(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text("Something went wrong!"),
                Text(error.toString()),
                const Text(
                    "Sorry, there was a fatal error and Commet was unable to start. Please copy the error details and report this issue on GitHub"),
                const Text(
                    "Make sure to remove any personal/sensitive information before submitting the report!"),
                ElevatedButton(
                    onPressed: onCopyButtonPressed,
                    child: const Text("Copy to clipboard")),
                ElevatedButton(
                    onPressed: onReportButtonPressed,
                    child: const Text("Report Issue")),
                Text(trace.toString())
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onCopyButtonPressed() async {
    var data = await getErrorData();
    Clipboard.setData(ClipboardData(text: data));
  }

  Future<String> getErrorData() async {
    var deviceInfo = await DeviceInfoPlugin().deviceInfo;
    return """
Fatal Error Occurred!
$error

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

<details open>
<summary>Stack Trace</summary>
<br>

```
${trace.toString()}
```

</details>
""";
  }

  void onReportButtonPressed() async {
    var data = await getErrorData();
    var uri = Uri.https("github.com", "/commetchat/commet/issues/new", {
      "title": "Fatal error occurred on app startup",
      "body": data,
      "labels": "bug",
    });

    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
