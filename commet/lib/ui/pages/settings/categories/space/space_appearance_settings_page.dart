import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/space_banner/space_banner_component.dart';
import 'package:commet/ui/pages/settings/categories/room/appearance/room_appearance_settings_view.dart';
import 'package:commet/utils/picker_utils.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class SpaceAppearanceSettingsPage extends StatefulWidget {
  const SpaceAppearanceSettingsPage({super.key, required this.space});
  final Space space;
  @override
  State<SpaceAppearanceSettingsPage> createState() =>
      _SpaceAppearanceSettingsPageState();
}

class _SpaceAppearanceSettingsPageState
    extends State<SpaceAppearanceSettingsPage> {
  ImageProvider? image;
  bool uploading = false;

  @override
  void initState() {
    image = widget.space.getComponent<SpaceBannerComponent>()?.banner;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoomAppearanceSettingsView(
          avatar: widget.space.avatar,
          displayName: widget.space.displayName,
          identifier: widget.space.identifier,
          onImagePicked: onAvatarPicked,
          onNameChanged: setName,
          canEditName: widget.space.permissions.canEditName,
          canEditAvatar: widget.space.permissions.canEditAvatar,
        ),
        SizedBox(
          height: 12,
        ),
        tiamat.Text.labelLow("Set Banner:"),
        ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                image: image != null
                    ? DecorationImage(image: image!, fit: BoxFit.cover)
                    : null),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  var result = await PickerUtils.pickImageAndCrop(context,
                      aspectRatio: 16 / 9);

                  if (result != null) {
                    setState(() {
                      image = null;
                      uploading = true;
                    });

                    await widget.space
                        .getComponent<SpaceBannerComponent>()
                        ?.setBanner(
                          result,
                        );

                    setState(() {
                      uploading = false;
                      image = MemoryImage(result);
                    });
                  }
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: uploading
                      ? Center(
                          child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator()))
                      : null,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  void onAvatarPicked(Uint8List bytes, String? mimeType) {
    widget.space.changeAvatar(bytes, mimeType);
  }

  void setName(String name) {
    widget.space.setDisplayName(name);
  }
}
