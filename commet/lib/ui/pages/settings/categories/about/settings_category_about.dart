import 'package:commet/config/build_config.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:commet/utils/link_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiamat/atoms/panel.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class SettingsCategoryAbout implements SettingsCategory {
  @override
  List<SettingsTab> get tabs => List.from([
        SettingsTab(
            label: "About",
            icon: Icons.info_outline,
            pageBuilder: (context) {
              return const _AppInfo();
            }),
      ]);

  @override
  String? get title => null;
}

class _AppInfo extends StatefulWidget {
  const _AppInfo();

  @override
  State<_AppInfo> createState() => _AppInfoState();
}

class _AppInfoState extends State<_AppInfo> {
  BaseDeviceInfo? deviceInfo;
  @override
  void initState() {
    super.initState();
    loadDeviceInfo();
  }

  Future<void> loadDeviceInfo() async {
    var info = await DeviceInfoPlugin().deviceInfo;
    setState(() {
      deviceInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SvgPicture.asset(
                  "assets/images/app_icon/icon.svg",
                  theme: SvgTheme(
                      currentColor: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ),
            Flexible(
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const tiamat.Text.largeTitle(BuildConfig.appName),
                      const tiamat.Text.labelEmphasised(
                          BuildConfig.VERSION_TAG),
                      const tiamat.Text.labelLow(
                          "${BuildConfig.GIT_HASH} ${BuildConfig.BUILD_DETAIL}"),
                      if (deviceInfo != null)
                        Row(
                          children: [
                            if (deviceInfo!.data["name"] is String)
                              tiamat.Text.labelLow(
                                  deviceInfo!.data["name"]!.toString()),
                            const SizedBox(
                              width: 10,
                            ),
                            if (deviceInfo!.data["version"] is String)
                              tiamat.Text.labelLow(
                                  deviceInfo!.data["version"]!.toString())
                          ],
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: tiamat.IconButton(
                      icon: Icons.copy,
                      onPressed: copySystemInfo,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Panel(
            header: "Credits",
            child: MarkdownBody(
              onTapLink: (text, href, title) =>
                  href != null ? LinkUtils.open(Uri.parse(href)) : null,
              data: """
[Twemoji](https://twemoji.twitter.com/) © Copyright 2020 Twitter, Inc and other contributors used under the terms of CC-BY 4.0.
""",
            )),
      ],
    );
  }

  copySystemInfo() {
    var data = """
<details open>
<summary>Device Information</summary>
<br>

**Device**
Platform: `${BuildConfig.PLATFORM}`
Version: `${BuildConfig.VERSION_TAG}`
Git Hash: `${BuildConfig.GIT_HASH}`
Detail: `${BuildConfig.BUILD_DETAIL}`


**System Info**
${deviceInfo?.data["name"] is String ? "Name: `${deviceInfo!.data["name"]}`" : ""}
${deviceInfo?.data["version"] is String ? "Version: `${deviceInfo!.data["version"]}`" : ""}
${deviceInfo?.data["product"] is String ? "Product: `${deviceInfo!.data["product"]}`" : ""}
</details>
""";

    Clipboard.setData(ClipboardData(text: data));
  }
}