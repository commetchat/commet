import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/components/user_color/user_color_component.dart';
import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/ui/molecules/message_input.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/ui/organisms/user_profile/user_profile_view.dart';
import 'package:commet/utils/picker_utils.dart';
import 'package:commet/utils/timezone_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class UserProfile extends StatefulWidget {
  const UserProfile(
      {super.key,
      required this.userId,
      this.width = 700,
      this.bannerHeight = 230.0,
      required this.client,
      this.maxBioHeight = 200,
      this.doSafeArea = true,
      this.showMessageButton = true,
      this.dismiss});
  final Client client;
  final String userId;
  final double bannerHeight;
  final double width;
  final double maxBioHeight;
  final Function? dismiss;
  final bool doSafeArea;
  final bool showMessageButton;

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
  UserPresence? presence;
  String? timezone;
  String? bioText;
  List<String> pronouns = const [];
  List<ProfileBadge> badges = [];

  @override
  void initState() {
    super.initState();
    component = widget.client.getComponent<UserProfileComponent>()!;

    component.getProfile(widget.userId).then((value) async {
      await stateFromProfile(value);
    });
  }

  Future<void> stateFromProfile(Profile? value) async {
    banner = value?.banner;
    avatar = value?.avatar;

    if (value case ProfileWithBadges p) {
      badges = await p.getBadges();
    }

    ColorScheme? scheme;
    Brightness? brightness;

    if (avatar case MatrixMxcImage mxc) {
      // create a new image instance so we can load fullres without it loading everywhere
      avatar = MatrixMxcImage(mxc.identifier, mxc.client,
          doThumbnail: false, doFullres: true, autoLoadFullRes: true);
    }

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

    await TimezoneUtils.instance.init();

    if (brightness == null)
      brightness = Theme.of(context).colorScheme.brightness;

    if (scheme == null) {
      if (avatar != null) {
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

    await Future.wait<dynamic>([
      if (banner != null) precacheImage(banner!, context),
      if (avatar != null) precacheImage(avatar!, context),
    ]);

    setState(() {
      theme = Theme.of(context).copyWith(colorScheme: scheme);
      profile = value;
      displayName = value?.displayName;

      if (profile case ProfileWithTimezone p) {
        timezone = p.timezone;
      }

      if (profile case ProfileWithPronouns p) {
        pronouns = p.pronouns;
      }

      if (profile case ProfileWithPresence p) {
        presence = p.precence;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return SizedBox(
          height: 300, child: const Center(child: CircularProgressIndicator()));
    }

    Widget? bio;

    if (profile case ProfileWithBio p) {
      if (p.hasBio || bioText != null) {
        bio = p.buildBio(context, theme!, overrideText: bioText);
      }
    }

    return Theme(
      data: theme!,
      child: UserProfileView(
        userAvatar: avatar,
        displayName: displayName!,
        identifier: profile!.identifier,
        userColor: profile!.defaultColor,
        userBanner: banner,
        presence: presence,
        timezone: timezone,
        bannerHeight: widget.bannerHeight,
        width: widget.width,
        doSafeArea: widget.doSafeArea,
        maxBioHeight: widget.maxBioHeight,
        showMessageButton: widget.showMessageButton,
        isSelf: widget.client.self!.identifier == profile!.identifier,
        onMessageButtonClicked: openDirectMessage,
        onSetBanner: setBanner,
        setPreviewColor: setPreviewColor,
        setPreviewBrightness: setPreviewBrightness,
        removeTimezone: removeTimezone,
        onChangeName: changeName,
        savePreviewTheme: savePreviewTheme,
        setBio: setBio,
        clearBio: clearBio,
        badges: badges,
        bio: bio,
        onSetAvatar: setAvatar,
        setColorOverride: setColorOverride,
        showSource: showSource,
        onSetStatus: setStatus,
        clearStatus: clearStatus,
        shareCurrentTimezone: shareTimezone,
        pronouns: pronouns,
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
    var result = await PickerUtils.pickImage();
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
    var result = await PickerUtils.pickImage();
    if (result == null) return;

    final bytes = await result.readAsBytes();

    setState(() {
      avatar = Image.memory(bytes).image;
    });

    await widget.client.setAvatar(bytes, "");
  }

  Future<void> setStatus() async {
    var text = await AdaptiveDialog.textPrompt(
      context,
      initialText: presence?.message?.message,
      title: "Change Status",
    );
    if (text != null) {
      var client = widget.client;
      client.getComponent<UserProfileComponent>()?.setStatus(text);
      client
          .getComponent<UserPresenceComponent>()
          ?.setStatus(UserPresenceStatus.online, message: text);

      setState(() {
        presence = UserPresence(UserPresenceStatus.online,
            message: UserPresenceMessage(text, PresenceMessageType.userCustom));
      });
    }
  }

  Future<void> clearStatus() async {
    var client = widget.client;
    await client.getComponent<UserProfileComponent>()?.setStatus(null);

    await client.getComponent<UserPresenceComponent>()?.setStatus(
        UserPresenceStatus.online,
        message: null,
        clearMessage: true);

    setState(() {
      presence = UserPresence(UserPresenceStatus.online);
    });
  }

  void showSource() {
    AdaptiveDialog.show(
      context,
      title: "Source",
      builder: (context) {
        return SizedBox(
          width: 1000,
          child: SelectionArea(
            child: ExpandableCodeBlock(
                expanded: true, text: profile!.source, language: "json"),
          ),
        );
      },
    );
  }

  Future<void> shareTimezone() async {
    final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    if (await AdaptiveDialog.confirmation(context,
            prompt:
                "Are you sure you want to share your timezone '${currentTimeZone.identifier}' publicly?") ==
        true) {
      setState(() {
        timezone = currentTimeZone.identifier;
      });

      print(currentTimeZone.identifier);
      return widget.client
          .getComponent<UserProfileComponent>()
          ?.setTimezone(currentTimeZone.identifier);
    }
  }

  Future<void> removeTimezone() async {
    await widget.client.getComponent<UserProfileComponent>()?.removeTimezone();

    setState(() {
      timezone = null;
    });
  }

  Future<void> setBio() async {
    AdaptiveDialog.show(context, builder: (context) {
      String? plaintext;

      if (profile case ProfileWithBio p) {
        plaintext = p.plaintextBio;
      }

      return SizedBox(
        width: 600,
        child: MessageInput(
          hintText: "Write about yourself!",
          initialText: bioText ?? plaintext,
          showAttachmentButton: false,
          client: widget.client,
          showGifSearch: false,
          disableEnterToSend: true,
          compact: true,
          enableKeyboardAdapter: false,
          availibleEmoticons:
              widget.client.getComponent<EmoticonComponent>()?.availablePacks,
          onSendMessage: (message, {overrideClient}) {
            widget.client.getComponent<UserProfileComponent>()?.setBio(message);

            setState(() {
              bioText = message;
            });

            Navigator.of(context).pop();

            return MessageInputSendResult.success;
          },
        ),
      );
    });
  }

  Future<void> clearBio() async {
    setState(() {
      bioText = null;
    });

    await widget.client.getComponent<UserProfileComponent>()?.removeBio();

    component.getProfile(widget.userId).then((value) async {
      await stateFromProfile(value);
    });
  }
}
