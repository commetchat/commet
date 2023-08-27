// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

import 'package:tiamat/atoms/avatar.dart';
import 'package:tiamat/atoms/button.dart';
import 'package:tiamat/atoms/checkbox.dart';
import 'package:tiamat/atoms/circle_button.dart';
import 'package:tiamat/atoms/dropdown_selector.dart';
import 'package:tiamat/atoms/glass_tile.dart';
import 'package:tiamat/atoms/icon_button.dart';
import 'package:tiamat/atoms/icon_toggle.dart';
import 'package:tiamat/atoms/image_button.dart';
import 'package:tiamat/atoms/panel.dart';
import 'package:tiamat/atoms/popup_dialog.dart';
import 'package:tiamat/atoms/radio_button.dart';
import 'package:tiamat/atoms/seperator.dart';
import 'package:tiamat/atoms/slider.dart';
import 'package:tiamat/atoms/switch.dart';
import 'package:tiamat/atoms/text.dart';
import 'package:tiamat/atoms/text_button.dart';
import 'package:tiamat/atoms/text_input.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/atoms/toggleable_list.dart';
import 'package:widgetbook/widgetbook.dart';

final directories = <WidgetbookNode>[
  WidgetbookFolder(
    name: 'atoms',
    children: [
      WidgetbookComponent(
        name: 'IconButton',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbIconButton(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'PopupDialog',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbpopupDialog(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'RadioButton',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbRadioButton(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'CircleButton',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbcircleButton(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'TextButton',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbiconUseCase(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'ToggleableList',
        useCases: [
          WidgetbookUseCase(
            name: 'Toggleable String',
            builder: (context) => wbToggleableList(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'Text',
        useCases: [
          WidgetbookUseCase(
            name: 'Label',
            builder: (context) => wbtextLabelUseCase(context),
          ),
          WidgetbookUseCase(
            name: 'Tiny',
            builder: (context) => wbtextTinyUseCase(context),
          ),
          WidgetbookUseCase(
            name: 'Body',
            builder: (context) => wbtextBodyUseCase(context),
          ),
          WidgetbookUseCase(
            name: 'Error',
            builder: (context) => wbtextErrorUseCase(context),
          ),
          WidgetbookUseCase(
            name: 'Title',
            builder: (context) => wbtextTitleUseCase(context),
          ),
          WidgetbookUseCase(
            name: 'Name',
            builder: (context) => wbtextNameUseCase(context),
          ),
          WidgetbookUseCase(
            name: 'All',
            builder: (context) => wbtextAllUseCase(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'Checkbox',
        useCases: [
          WidgetbookUseCase(
            name: 'Large',
            builder: (context) => wbCheckBox(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'DropdownSelector',
        useCases: [
          WidgetbookUseCase(
            name: 'String Selector',
            builder: (context) => wbDropdownSelector(context),
          ),
          WidgetbookUseCase(
            name: 'Multi Line Text',
            builder: (context) => wbDropdownSelectorMultiLine(context),
          ),
          WidgetbookUseCase(
            name: 'Avatar Selector',
            builder: (context) => wbDropdownAvatarSelector(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'GlassTile',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbtileGlass(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'Panel',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbPanel(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'Switch',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbswitch(context),
          ),
          WidgetbookUseCase(
            name: 'No Icons',
            builder: (context) => wbswitchNoIcons(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'IconToggle',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbIconToggle(context),
          ),
          WidgetbookUseCase(
            name: 'On',
            builder: (context) => wbIconToggleOn(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'ImageButton',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbimageButton(context),
          ),
          WidgetbookUseCase(
            name: 'Icon',
            builder: (context) => wbimageButtonIcon(context),
          ),
          WidgetbookUseCase(
            name: 'Icon with Shadow',
            builder: (context) => wbimageButtonIconWithShadow(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'TextInput',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbTextInput(context),
          ),
          WidgetbookUseCase(
            name: 'With Icon',
            builder: (context) => wbTextInputWithIcon(context),
          ),
          WidgetbookUseCase(
            name: 'Multiline',
            builder: (context) => wbTextInputMultiline(context),
          ),
          WidgetbookUseCase(
            name: 'Multiline with Icon',
            builder: (context) => wbTextInputMultilineWithIcon(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'Button',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbButton(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'Slider',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbslider(context),
          ),
          WidgetbookUseCase(
            name: 'Divided',
            builder: (context) => wbsliderDivided(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'Tile',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbtileSurface(context),
          ),
          WidgetbookUseCase(
            name: 'Low 1',
            builder: (context) => wbtileSurfaceLow1(context),
          ),
          WidgetbookUseCase(
            name: 'Low 2',
            builder: (context) => wbtileSurfaceLow2(context),
          ),
          WidgetbookUseCase(
            name: 'Low 3',
            builder: (context) => wbtileSurfaceLow3(context),
          ),
          WidgetbookUseCase(
            name: 'Low 4',
            builder: (context) => wbtileSurfaceLow4(context),
          ),
          WidgetbookUseCase(
            name: 'High',
            builder: (context) => wbtileSurfaceHigh(context),
          ),
          WidgetbookUseCase(
            name: 'All',
            builder: (context) => tileAll(context),
          ),
          WidgetbookUseCase(
            name: 'All with border',
            builder: (context) => tileAllBorders(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'Avatar',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbavatarDefault(context),
          ),
          WidgetbookUseCase(
            name: 'Large',
            builder: (context) => wbavatarLarge(context),
          ),
          WidgetbookUseCase(
            name: 'Placeholder',
            builder: (context) => wbavatarPlaceholder(context),
          ),
          WidgetbookUseCase(
            name: 'Placeholder Large',
            builder: (context) => wbavatarPlaceholderLarge(context),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'Seperator',
        useCases: [
          WidgetbookUseCase(
            name: 'Default',
            builder: (context) => wbseperatorUseCase(context),
          ),
        ],
      ),
    ],
  ),
];
