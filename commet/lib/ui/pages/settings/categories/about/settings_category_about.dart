import 'package:commet/config/build_config.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/ui/pages/settings/settings_category.dart';
import 'package:commet/ui/pages/settings/settings_tab.dart';
import 'package:commet/utils/link_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiamat/atoms/panel.dart';
import 'package:tiamat/atoms/tile.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class SettingsCategoryAbout implements SettingsCategory {
  @override
  List<SettingsTab> get tabs => List.from([
        SettingsTab(
            label: "About",
            icon: Icons.info_outline,
            pageBuilder: (context) {
              return _AppInfo();
            }),
      ]);

  @override
  String? get title => null;
}

class _AppInfo extends StatelessWidget {
  const _AppInfo({super.key});

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
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tiamat.Text.largeTitle(BuildConfig.appName),
                  tiamat.Text.labelEmphasised(BuildConfig.VERSION_TAG),
                  tiamat.Text.labelLow(BuildConfig.GIT_HASH)
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: tiamat.IconButton(
                size: 20,
                icon: Icons.copy,
              ),
            )
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
            ))
      ],
    );
  }
}
