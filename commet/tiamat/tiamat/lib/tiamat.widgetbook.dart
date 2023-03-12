// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// WidgetbookGenerator
// **************************************************************************

import 'dart:core';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/atoms/button.dart';
import 'package:tiamat/atoms/circle_button.dart';
import 'package:tiamat/atoms/glass_tile.dart';
import 'package:tiamat/atoms/image_button.dart';
import 'package:tiamat/atoms/popup_dialog.dart';
import 'package:tiamat/atoms/seperator.dart';
import 'package:tiamat/atoms/shader_background.dart';
import 'package:tiamat/atoms/slider.dart';
import 'package:tiamat/atoms/text.dart';
import 'package:tiamat/atoms/text_button.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/config/app_config.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
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
        name: 'Tiamat',
      ),
      themes: [
        WidgetbookTheme(
          name: 'Dark',
          data: darkTheme(),
        ),
        WidgetbookTheme(
          name: 'Light',
          data: lightTheme(),
        ),
        WidgetbookTheme(
          name: 'Glass',
          data: glassTheme(),
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
          name: 'iMac M1',
          resolution: Resolution(
            nativeSize: DeviceSize(
              height: 2520.0,
              width: 4480.0,
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
              name: 'atoms',
              widgets: [
                WidgetbookComponent(
                  name: 'PopupDialog',
                  useCases: [
                    WidgetbookUseCase(
                      name: 'Default',
                      builder: (context) => wb_popupDialog(context),
                    ),
                  ],
                ),
                WidgetbookComponent(
                  name: 'CircleButton',
                  useCases: [
                    WidgetbookUseCase(
                      name: 'Default',
                      builder: (context) => wb_circleButton(context),
                    ),
                  ],
                ),
                WidgetbookComponent(
                  name: 'TextButton',
                  useCases: [
                    WidgetbookUseCase(
                      name: 'Default',
                      builder: (context) => wb_iconUseCase(context),
                    ),
                  ],
                ),
                WidgetbookComponent(
                  name: 'Text',
                  useCases: [
                    WidgetbookUseCase(
                      name: 'Label',
                      builder: (context) => wb_textLabelUseCase(context),
                    ),
                    WidgetbookUseCase(
                      name: 'Tiny',
                      builder: (context) => wb_textTinyUseCase(context),
                    ),
                    WidgetbookUseCase(
                      name: 'Body',
                      builder: (context) => wb_textBodyUseCase(context),
                    ),
                    WidgetbookUseCase(
                      name: 'Error',
                      builder: (context) => wb_textErrorUseCase(context),
                    ),
                    WidgetbookUseCase(
                      name: 'Title',
                      builder: (context) => wb_textTitleUseCase(context),
                    ),
                    WidgetbookUseCase(
                      name: 'All',
                      builder: (context) => wb_textAllUseCase(context),
                    ),
                  ],
                ),
                WidgetbookComponent(
                  name: 'ImageButton',
                  useCases: [
                    WidgetbookUseCase(
                      name: 'Default',
                      builder: (context) => wb_imageButton(context),
                    ),
                  ],
                ),
                WidgetbookComponent(
                  name: 'Button',
                  useCases: [
                    WidgetbookUseCase(
                      name: 'Default',
                      builder: (context) => wb_Button(context),
                    ),
                  ],
                ),
                WidgetbookComponent(
                  name: 'Slider',
                  useCases: [
                    WidgetbookUseCase(
                      name: 'Default',
                      builder: (context) => wb_slider(context),
                    ),
                    WidgetbookUseCase(
                      name: 'Divided',
                      builder: (context) => wb_sliderDivided(context),
                    ),
                  ],
                ),
                WidgetbookComponent(
                  name: 'Tile',
                  useCases: [
                    WidgetbookUseCase(
                      name: 'Default',
                      builder: (context) => wb_tileSurface(context),
                    ),
                    WidgetbookUseCase(
                      name: 'Low 1',
                      builder: (context) => wb_tileSurfaceLow1(context),
                    ),
                    WidgetbookUseCase(
                      name: 'Low 2',
                      builder: (context) => wb_tileSurfaceLow2(context),
                    ),
                    WidgetbookUseCase(
                      name: 'Low 3',
                      builder: (context) => wb_tileSurfaceLow3(context),
                    ),
                    WidgetbookUseCase(
                      name: 'Low 4',
                      builder: (context) => wb_tileSurfaceLow4(context),
                    ),
                    WidgetbookUseCase(
                      name: 'High',
                      builder: (context) => wb_tileSurfaceHigh(context),
                    ),
                    WidgetbookUseCase(
                      name: 'All',
                      builder: (context) => tileAll(context),
                    ),
                  ],
                ),
                WidgetbookComponent(
                  name: 'GlassTile',
                  useCases: [
                    WidgetbookUseCase(
                      name: 'Default',
                      builder: (context) => wb_tileGlass(context),
                    ),
                  ],
                ),
                WidgetbookComponent(
                  name: 'Seperator',
                  useCases: [
                    WidgetbookUseCase(
                      name: 'Default',
                      builder: (context) => wb_seperatorUseCase(context),
                    ),
                  ],
                ),
              ],
              folders: [],
            ),
          ],
          widgets: [],
        ),
      ],
    );
  }
}
