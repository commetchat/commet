import 'dart:async';
import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/space_banner/space_banner_component.dart';
import 'package:commet/ui/pages/settings/categories/room/appearance/room_appearance_settings_view.dart';
import 'package:commet/utils/picker_utils.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

enum _BannerAction { 
  change, 
  remove, 
  cancel 
}

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
  late StreamSubscription _sub;

  @override
  void initState() {
    image = widget.space.getComponent<SpaceBannerComponent>()?.banner;
    super.initState();
    _sub = widget.space.onUpdate.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool canEditBanner =
        widget.space.getComponent<SpaceBannerComponent>()?.canEditBanner ==
            true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoomAppearanceSettingsView(
          avatar: widget.space.avatar,
          displayName: widget.space.displayName,
          identifier: widget.space.identifier,
          onImagePicked: onAvatarPicked,
          onNameChanged: setName,
          setTopic: widget.space.setTopic,
          client: widget.space.client,
          color: widget.space.color,
          topic: widget.space.topic,
          canEditName: widget.space.permissions.canEditName,
          canEditTopic: widget.space.permissions.canEditTopic,
          canEditAvatar: widget.space.permissions.canEditAvatar,
        ),
        SizedBox(
          height: 12,
        ),
        if (canEditBanner) tiamat.Text.labelLow("Set Banner:"),
        if (canEditBanner)
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

                    final action = await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text("Change Banner"),
                            content: Text("Do you want to change the banner?"),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(_BannerAction.cancel);
                                  },
                                  child: Text("Cancel")),
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(_BannerAction.remove);
                                  },
                                  child: Text("Remove")),
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(_BannerAction.change);
                                  },
                                  child: Text("Change")),
                            ],
                          );
                        });

                    if (action == _BannerAction.remove) {
                      setState(() {
                        image = null;
                        uploading = true;
                      });
                      await widget.space
                          .getComponent<SpaceBannerComponent>()
                          ?.removeBanner();
                      setState(() {
                        uploading = false;
                      });
                      return;
                    } else if (action != _BannerAction.change) {
                      return;
                    }

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
