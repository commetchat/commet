// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// WidgetbookGenerator
// **************************************************************************

import 'dart:core';
import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/simulated/simulated_client.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/generated/l10n.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/pages/add_space/add_space.dart';
import 'package:commet/ui/pages/add_space/add_space_view.dart';
import 'package:commet/ui/pages/chat/chat_page.dart';
import 'package:commet/ui/pages/loading/loading_page.dart';
import 'package:commet/ui/pages/loading/loading_page_view.dart';
import 'package:commet/ui/pages/login/login_page.dart';
import 'package:commet/ui/pages/login/login_page_view.dart';
import 'package:commet/ui/pages/matrix/verification/matrix_verification_page.dart';
import 'package:commet/ui/pages/matrix/verification/matrix_verification_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:matrix/encryption/utils/key_verification.dart';
import 'package:provider/provider.dart';
import 'package:scaled_app/scaled_app.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/config/style/theme_changer.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:tiamat/config/style/theme_glass.dart';
import 'package:tiamat/config/style/theme_light.dart';
import 'package:tiamat/tiamat.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  runApp(HotReload());
}

class HotReload extends StatelessWidget {
  const HotReload({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      appInfo: AppInfo(
        name: 'Commet',
      ),
      themes: [
        WidgetbookTheme(
          name: 'Dark',
          data: commetDarkTheme(),
        ),
        WidgetbookTheme(
          name: 'Light',
          data: commetLightTheme(),
        ),
        WidgetbookTheme(
          name: 'Glass',
          data: commetGlassTheme(),
        ),
      ],
      devices: [
        Device(
          name: 'iPhone 12',
          resolution: Resolution(
            nativeSize: DeviceSize(
              height: 2532.0,
              width: 1170.0,
            ),
            scaleFactor: 3.0,
          ),
          type: DeviceType.mobile,
        ),
        Device(
          name: 'MacBook 13"',
          resolution: Resolution(
            nativeSize: DeviceSize(
              height: 1600.0,
              width: 2560.0,
            ),
            scaleFactor: 2.0,
          ),
          type: DeviceType.desktop,
        ),
      ],
      categories: [
        WidgetbookCategory(
          name: 'use cases',
          folders: [
            WidgetbookFolder(
              name: 'ui',
              widgets: [],
              folders: [
                WidgetbookFolder(
                  name: 'molecules',
                  widgets: [
                    WidgetbookComponent(
                      name: 'UserPanel',
                      useCases: [
                        WidgetbookUseCase(
                          name: 'No Avatar',
                          builder: (context) => wbUserPanelDefault(context),
                        ),
                        WidgetbookUseCase(
                          name: 'With Avatar',
                          builder: (context) => wbUserPanelWithAvatar(context),
                        ),
                      ],
                    ),
                  ],
                  folders: [],
                ),
                WidgetbookFolder(
                  name: 'pages',
                  widgets: [],
                  folders: [
                    WidgetbookFolder(
                      name: 'loading',
                      widgets: [
                        WidgetbookComponent(
                          name: 'LoadingPageView',
                          useCases: [
                            WidgetbookUseCase(
                              name: 'Loading Page',
                              builder: (context) => wbLoadingpage(context),
                            ),
                          ],
                        ),
                      ],
                      folders: [],
                    ),
                    WidgetbookFolder(
                      name: 'matrix',
                      widgets: [],
                      folders: [
                        WidgetbookFolder(
                          name: 'verification',
                          widgets: [
                            WidgetbookComponent(
                              name: 'MatrixVerificationPageView',
                              useCases: [
                                WidgetbookUseCase(
                                  name: 'Check Emojis',
                                  builder: (context) =>
                                      wbSASCheckEmojis(context),
                                ),
                                WidgetbookUseCase(
                                  name: 'Loading',
                                  builder: (context) =>
                                      sbVerificationLoading(context),
                                ),
                                WidgetbookUseCase(
                                  name: 'Request Received',
                                  builder: (context) =>
                                      wbSASRequestReceived(context),
                                ),
                                WidgetbookUseCase(
                                  name: 'Done',
                                  builder: (context) =>
                                      wbVerificationSuccess(context),
                                ),
                              ],
                            ),
                          ],
                          folders: [],
                        ),
                      ],
                    ),
                    WidgetbookFolder(
                      name: 'add_space',
                      widgets: [
                        WidgetbookComponent(
                          name: 'AddSpaceView',
                          useCases: [
                            WidgetbookUseCase(
                              name: 'Multiple Accounts',
                              builder: (context) =>
                                  wbAddSpacePageMultiAccount(context),
                            ),
                            WidgetbookUseCase(
                              name: 'Single Account',
                              builder: (context) =>
                                  wbAddSpacePageSingleAccount(context),
                            ),
                          ],
                        ),
                      ],
                      folders: [],
                    ),
                    WidgetbookFolder(
                      name: 'login',
                      widgets: [
                        WidgetbookComponent(
                          name: 'LoginPageView',
                          useCases: [
                            WidgetbookUseCase(
                              name: 'Login Page',
                              builder: (context) => wbLoginPage(context),
                            ),
                          ],
                        ),
                      ],
                      folders: [],
                    ),
                  ],
                ),
              ],
            ),
          ],
          widgets: [],
        ),
      ],
    );
  }
}
