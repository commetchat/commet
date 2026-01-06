import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/components/user_color/user_color_component.dart';
import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/ui/organisms/user_profile/user_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserProfile extends StatefulWidget {
  const UserProfile(
      {super.key,
      required this.userId,
      this.width = 700,
      required this.client,
      this.dismiss});
  final Client client;
  final String userId;
  final double width;
  final Function? dismiss;

  @override
  State<UserProfile> createState() => _UserProfileState();

  static Future<T?> show<T extends Object?>(
    BuildContext context, {
    required Client client,
    required String userId,
    bool scrollable = true,
    bool dismissible = true,
    double padding = 8.0,
    double initialHeightMobile = 0.5,
  }) async {
    if (Layout.desktop)
      return showGeneralDialog(
          context: context,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Theme(
              data: Theme.of(context),
              child: Center(child: UserProfile(userId: userId, client: client)),
            );
          },
          barrierLabel: "USER_PROFILE_BARRIER",
          barrierDismissible: dismissible,
          transitionDuration: const Duration(milliseconds: 300),
          transitionBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position:
                    Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
                        .animate(CurvedAnimation(
                            parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ));

    return showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      useSafeArea: false,
      builder: (context) {
        return UserProfile(
          userId: userId,
          client: client,
          width: double.infinity,
        );
      },
    );
  }
}

class _UserProfileState extends State<UserProfile> {
  Profile? profile;
  ThemeData? theme;

  late UserProfileComponent component;

  ImageProvider? banner;
  String? displayName;
  ImageProvider? avatar;

  @override
  void initState() {
    super.initState();
    component = widget.client.getComponent<UserProfileComponent>()!;

    component.getProfile(widget.userId).then((value) async {
      banner = value?.banner;

      ColorScheme? scheme;
      Brightness? brightness;

      if (value case ProfileWithColorScheme p) {
        if (p.brightness != null) {
          brightness = p.brightness!;

          if (p.color != null) {
            scheme = ColorScheme.fromSeed(
                seedColor: p.color!,
                brightness: brightness,
                dynamicSchemeVariant: DynamicSchemeVariant.content);
          }
        }
      }

      if (banner != null) {
        await precacheImage(banner!, context);
      }

      if (brightness == null)
        brightness = Theme.of(context).colorScheme.brightness;

      if (scheme == null) {
        if (value?.avatar != null || value?.avatar != null) {
          scheme = await ColorScheme.fromImageProvider(
              provider: value!.banner ?? value.avatar!,
              brightness: brightness,
              dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot);
        } else {
          scheme = ColorScheme.fromSeed(
              seedColor: value!.defaultColor,
              brightness: brightness,
              dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot);
        }
      }

      setState(() {
        theme = Theme.of(context).copyWith(colorScheme: scheme);
        profile = value;
        displayName = value?.displayName;
        avatar = value?.avatar;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return SizedBox(
          height: 300, child: const Center(child: CircularProgressIndicator()));
    }

    UserPresence? presence;
    if (profile case ProfileWithPresence p) {
      presence = p.precence;
    }

    return Theme(
      data: theme!,
      child: UserProfileView(
        userAvatar: avatar!,
        displayName: displayName!,
        identifier: profile!.identifier,
        userColor: profile!.defaultColor,
        userBanner: banner,
        presence: presence,
        width: widget.width,
        isSelf: widget.client.self!.identifier == profile!.identifier,
        onMessageButtonClicked: openDirectMessage,
        onSetBanner: setBanner,
        setPreviewColor: setPreviewColor,
        setPreviewBrightness: setPreviewBrightness,
        onChangeName: changeName,
        savePreviewTheme: savePreviewTheme,
        onSetAvatar: setAvatar,
        setColorOverride: setColorOverride,
        hasColorOverride: widget.client
                .getComponent<UserColorComponent>()
                ?.getColor(profile!.identifier) !=
            null,
      ),
    );
  }

  Future<void> openDirectMessage() async {
    final component = widget.client.getComponent<DirectMessagesComponent>();
    if (component == null) {
      return;
    }

    var existingRooms = component.directMessageRooms.where((element) =>
        profile!.identifier == component.getDirectMessagePartnerId(element));

    if (existingRooms.isNotEmpty == true) {
      EventBus.openRoom
          .add((existingRooms.first.identifier, widget.client.identifier));
    } else {
      var room = await component.createDirectMessage(profile!.identifier);
      if (room != null) {
        EventBus.openRoom.add((room.identifier, widget.client.identifier));
      }
    }

    Navigator.of(context).pop();
  }

  Future<void> setBanner() async {
    var picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result == null) return;

    final bytes = await result.readAsBytes();

    setState(() {
      banner = Image.memory(bytes).image;
    });

    await component.setBanner(bytes);
  }

  Color previewColor = Colors.blue;
  Brightness previewBrightness = Brightness.dark;

  void setPreviewColor(Color color) {
    setState(() {
      previewColor = color;
      updatePreviewTheme();
    });
  }

  void updatePreviewTheme() {
    theme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
          seedColor: previewColor,
          brightness: previewBrightness,
          dynamicSchemeVariant: DynamicSchemeVariant.content),
    );
  }

  Future<void> savePreviewTheme() async {
    await component.setProfileColorScheme(previewColor, previewBrightness);
  }

  Future<void> setPreviewBrightness(Brightness p1) async {
    setState(() {
      previewBrightness = p1;
      updatePreviewTheme();
    });
  }

  Future<void> setColorOverride(Color? color) async {
    var comp = widget.client.getComponent<UserColorComponent>();
    await comp?.setColor(widget.userId, color);
  }

  Future<void> changeName() async {
    var text = await AdaptiveDialog.textPrompt(
      context,
      initialText: displayName,
      title: "Change name",
    );
    if (text?.trim().isNotEmpty == true) {
      setState(() {
        displayName = text!.trim();

        widget.client.setDisplayName(text.trim());
      });
    }
  }

  Future<void> setAvatar() async {
    var picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result == null) return;

    final bytes = await result.readAsBytes();

    setState(() {
      avatar = Image.memory(bytes).image;
    });

    await widget.client.setAvatar(bytes, "");
  }
}
