// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:tiamat/atoms/avatar.dart' as _i2;
import 'package:tiamat/atoms/button.dart' as _i3;
import 'package:tiamat/atoms/checkbox.dart' as _i4;
import 'package:tiamat/atoms/circle_button.dart' as _i5;
import 'package:tiamat/atoms/dropdown_selector.dart' as _i6;
import 'package:tiamat/atoms/glass_tile.dart' as _i7;
import 'package:tiamat/atoms/icon_button.dart' as _i8;
import 'package:tiamat/atoms/icon_toggle.dart' as _i9;
import 'package:tiamat/atoms/image_button.dart' as _i10;
import 'package:tiamat/atoms/panel.dart' as _i11;
import 'package:tiamat/atoms/popup_dialog.dart' as _i12;
import 'package:tiamat/atoms/radio_button.dart' as _i13;
import 'package:tiamat/atoms/seperator.dart' as _i14;
import 'package:tiamat/atoms/slider.dart' as _i15;
import 'package:tiamat/atoms/switch.dart' as _i16;
import 'package:tiamat/atoms/text.dart' as _i17;
import 'package:tiamat/atoms/text_button.dart' as _i18;
import 'package:tiamat/atoms/text_input.dart' as _i19;
import 'package:tiamat/atoms/tile.dart' as _i20;
import 'package:tiamat/atoms/toggleable_list.dart' as _i21;
import 'package:widgetbook/widgetbook.dart' as _i1;

final directories = <_i1.WidgetbookNode>[
  _i1.WidgetbookFolder(
    name: 'atoms',
    children: [
      _i1.WidgetbookComponent(
        name: 'Avatar',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i2.wbavatarDefault,
          ),
          _i1.WidgetbookUseCase(
            name: 'Large',
            builder: _i2.wbavatarLarge,
          ),
          _i1.WidgetbookUseCase(
            name: 'Placeholder',
            builder: _i2.wbavatarPlaceholder,
          ),
          _i1.WidgetbookUseCase(
            name: 'Placeholder Large',
            builder: _i2.wbavatarPlaceholderLarge,
          ),
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'Button',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i3.wbButton,
          )
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'Checkbox',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Large',
            builder: _i4.wbCheckBox,
          )
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'CircleButton',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i5.wbcircleButton,
          )
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'DropdownSelector',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Avatar Selector',
            builder: _i6.wbDropdownAvatarSelector,
          ),
          _i1.WidgetbookUseCase(
            name: 'Multi Line Text',
            builder: _i6.wbDropdownSelectorMultiLine,
          ),
          _i1.WidgetbookUseCase(
            name: 'String Selector',
            builder: _i6.wbDropdownSelector,
          ),
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'GlassTile',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i7.wbtileGlass,
          )
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'IconButton',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i8.wbIconButton,
          )
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'IconToggle',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i9.wbIconToggle,
          ),
          _i1.WidgetbookUseCase(
            name: 'On',
            builder: _i9.wbIconToggleOn,
          ),
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'ImageButton',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i10.wbimageButton,
          ),
          _i1.WidgetbookUseCase(
            name: 'Icon',
            builder: _i10.wbimageButtonIcon,
          ),
          _i1.WidgetbookUseCase(
            name: 'Icon with Shadow',
            builder: _i10.wbimageButtonIconWithShadow,
          ),
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'Panel',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i11.wbPanel,
          )
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'PopupDialog',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i12.wbpopupDialog,
          )
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'RadioButton',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i13.wbRadioButton,
          )
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'Seperator',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i14.wbseperatorUseCase,
          )
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'Slider',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i15.wbslider,
          ),
          _i1.WidgetbookUseCase(
            name: 'Divided',
            builder: _i15.wbsliderDivided,
          ),
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'Switch',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i16.wbswitch,
          ),
          _i1.WidgetbookUseCase(
            name: 'No Icons',
            builder: _i16.wbswitchNoIcons,
          ),
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'Text',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'All',
            builder: _i17.wbtextAllUseCase,
          ),
          _i1.WidgetbookUseCase(
            name: 'Body',
            builder: _i17.wbtextBodyUseCase,
          ),
          _i1.WidgetbookUseCase(
            name: 'Error',
            builder: _i17.wbtextErrorUseCase,
          ),
          _i1.WidgetbookUseCase(
            name: 'Label',
            builder: _i17.wbtextLabelUseCase,
          ),
          _i1.WidgetbookUseCase(
            name: 'Name',
            builder: _i17.wbtextNameUseCase,
          ),
          _i1.WidgetbookUseCase(
            name: 'Tiny',
            builder: _i17.wbtextTinyUseCase,
          ),
          _i1.WidgetbookUseCase(
            name: 'Title',
            builder: _i17.wbtextTitleUseCase,
          ),
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'TextButton',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i18.wbiconUseCase,
          ),
          _i1.WidgetbookUseCase(
            name: 'With Avatar Placeholder',
            builder: _i18.wbiconUseCaseWithAvatarPlaceholder,
          ),
          _i1.WidgetbookUseCase(
            name: 'With Image',
            builder: _i18.wbiconUseCaseWithImage,
          ),
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'TextInput',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i19.wbTextInput,
          ),
          _i1.WidgetbookUseCase(
            name: 'Multiline',
            builder: _i19.wbTextInputMultiline,
          ),
          _i1.WidgetbookUseCase(
            name: 'Multiline with Icon',
            builder: _i19.wbTextInputMultilineWithIcon,
          ),
          _i1.WidgetbookUseCase(
            name: 'With Icon',
            builder: _i19.wbTextInputWithIcon,
          ),
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'Tile',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'All',
            builder: _i20.tileAll,
          ),
          _i1.WidgetbookUseCase(
            name: 'All with border',
            builder: _i20.tileAllBorders,
          ),
          _i1.WidgetbookUseCase(
            name: 'Default',
            builder: _i20.wbtileSurface,
          ),
          _i1.WidgetbookUseCase(
            name: 'High',
            builder: _i20.wbtileSurfaceHigh,
          ),
          _i1.WidgetbookUseCase(
            name: 'Low 1',
            builder: _i20.wbtileSurfaceLow1,
          ),
          _i1.WidgetbookUseCase(
            name: 'Low 2',
            builder: _i20.wbtileSurfaceLow2,
          ),
          _i1.WidgetbookUseCase(
            name: 'Low 3',
            builder: _i20.wbtileSurfaceLow3,
          ),
          _i1.WidgetbookUseCase(
            name: 'Low 4',
            builder: _i20.wbtileSurfaceLow4,
          ),
        ],
      ),
      _i1.WidgetbookComponent(
        name: 'ToggleableList',
        useCases: [
          _i1.WidgetbookUseCase(
            name: 'Toggleable String',
            builder: _i21.wbToggleableList,
          )
        ],
      ),
    ],
  )
];
