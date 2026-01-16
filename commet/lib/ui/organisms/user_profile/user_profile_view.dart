import 'dart:async';
import 'dart:ui';

import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/components/user_presence/user_presence_component.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/atoms/tiny_pill.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import 'package:timezone/standalone.dart' as tz;

class UserProfileView extends StatefulWidget {
  const UserProfileView(
      {super.key,
      this.userAvatar,
      required this.displayName,
      required this.userColor,
      this.userBanner,
      required this.identifier,
      required this.isSelf,
      this.presence,
      this.onSetBanner,
      this.timezone,
      this.bannerHeight = 230.0,
      this.width = 700,
      this.setPreviewColor,
      this.hasColorOverride = false,
      this.setPreviewBrightness,
      this.setColorOverride,
      this.shareCurrentTimezone,
      this.removeTimezone,
      this.onSetAvatar,
      this.bio,
      this.onSetStatus,
      this.editBadges,
      this.setBio,
      this.badges = const [],
      this.clearBio,
      this.showMessageButton = true,
      this.doSafeArea = true,
      this.onChangeName,
      this.maxBioHeight = 200,
      this.showSource,
      this.pronouns = const [],
      this.clearStatus,
      this.savePreviewTheme,
      this.onMessageButtonClicked});
  final ImageProvider? userAvatar;
  final ImageProvider? userBanner;
  final UserPresence? presence;
  final String displayName;
  final String identifier;
  final bool doSafeArea;
  final List<String> pronouns;
  final List<ProfileBadge> badges;
  final Color userColor;
  final bool isSelf;
  final bool showMessageButton;
  final double bannerHeight;
  final double maxBioHeight;
  final bool hasColorOverride;
  final String? timezone;
  final double width;
  final Future<void> Function()? onSetBanner;
  final Future<void> Function()? onSetAvatar;
  final Future<void> Function()? onSetStatus;
  final Future<void> Function()? onChangeName;
  final Future<void> Function()? shareCurrentTimezone;
  final Future<void> Function()? removeTimezone;
  final Future<void> Function()? setBio;
  final Future<void> Function()? clearBio;
  final Future<void> Function()? clearStatus;
  final Future<void> Function()? editBadges;
  final void Function()? showSource;
  final void Function(Color)? setPreviewColor;
  final Widget? bio;
  final Future<void> Function(Brightness)? setPreviewBrightness;
  final Future<void> Function()? onMessageButtonClicked;
  final Future<void> Function()? savePreviewTheme;
  final Future<void> Function(Color?)? setColorOverride;

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  bool isLoadingDirectMessage = false;

  String get promptOpenDirectMessage => Intl.message("Message",
      desc: "Prompt on the button to open a direct message with another user",
      name: "promptOpenDirectMessage");

  bool editingColorScheme = false;

  Timer? timezoneTimer;

  tz.TZDateTime? localTime;

  ScrollController bioScrollController = ScrollController();

  @override
  void initState() {
    if (widget.timezone != null) {
      timezoneTimer =
          Timer.periodic(Duration(seconds: 1), (_) => updateLocalTime());
      updateLocalTime();
    }

    super.initState();
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    timezoneTimer?.cancel();

    if (widget.timezone != null) {
      timezoneTimer =
          Timer.periodic(Duration(seconds: 1), (_) => updateLocalTime());
      updateLocalTime();
    }
  }

  @override
  void dispose() {
    timezoneTimer?.cancel();
    super.dispose();
  }

  void updateLocalTime() {
    try {
      setState(() {
        if (widget.timezone != null) ;
        var location = tz.getLocation(widget.timezone!);
        localTime = tz.TZDateTime.now(location);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    var background = Theme.of(context).colorScheme.primaryContainer;
    final bannerHeight = widget.bannerHeight;
    const avatarOverlap = 50.0;

    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(8),
      child: Container(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 0,
            children: [
              SizedBox(
                child: Stack(
                  children: [
                    SizedBox(
                      height: bannerHeight,
                      width: double.infinity,
                      child: widget.userBanner != null
                          ? Image(
                              image: widget.userBanner!,
                              fit: BoxFit.cover,
                            )
                          : widget.userAvatar != null
                              ? ClipRect(
                                  child: ImageFiltered(
                                    imageFilter: ImageFilter.blur(
                                        sigmaX: 40,
                                        sigmaY: 40,
                                        tileMode: TileMode.repeated),
                                    child: Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer,
                                      child: Image(
                                        image: widget.userAvatar!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow,
                                ),
                    ),
                    Align(
                        alignment: AlignmentGeometry.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadiusGeometry.circular(15),
                            child: SizedBox(
                                width: 30,
                                height: 30,
                                child: Material(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withAlpha(100),
                                  child: AdaptiveContextMenu(
                                    modal: true,
                                    items: contextMenuItems(context),
                                    child: Icon(
                                      Icons.more_vert,
                                      size: 15,
                                    ),
                                  ),
                                )),
                          ),
                        )),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          0, bannerHeight - avatarOverlap, 0, 0),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                0, avatarOverlap - 2, 0, 0),
                            child: Container(
                              color: background,
                              child: ScaledSafeArea(
                                  bottom: widget.doSafeArea,
                                  top: widget.doSafeArea,
                                  left: widget.doSafeArea,
                                  right: widget.doSafeArea,
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        8, avatarOverlap, 8, 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainer,
                                      ),
                                      child: Column(
                                        spacing: 8,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                12, 4, 12, 4),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    displayName(),
                                                    username(context),
                                                    pronouns(),
                                                  ],
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          0, 8, 0, 0),
                                                  child: Column(
                                                    spacing: 8,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      if (localTime != null)
                                                        userLocalTime(),
                                                      badges(),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                          if (widget.bio != null)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      8, 0, 8, 0),
                                              child: buildBio(context),
                                            ),
                                          if (!widget.isSelf &&
                                              widget.showMessageButton)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: tiamat.Button(
                                                text: promptOpenDirectMessage,
                                                onTap: clickMessageButton,
                                              ),
                                            )
                                        ],
                                      ),
                                    ),
                                  )),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                MouseRegion(
                                    cursor: widget.isSelf
                                        ? SystemMouseCursors.click
                                        : MouseCursor.defer,
                                    child: GestureDetector(
                                        onTap: widget.isSelf
                                            ? widget.onSetAvatar
                                            : null,
                                        child: tiamat.Avatar.large(
                                          border: BoxBorder.all(
                                              color: background,
                                              width: 8,
                                              strokeAlign: 0.9),
                                          image: widget.userAvatar,
                                          placeholderColor: widget.userColor,
                                          placeholderText: widget.displayName,
                                        ))),
                                if (widget.presence?.message != null)
                                  Flexible(
                                      child: buildPresenceDisplay(background))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Padding username(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: Opacity(
        opacity: 0.8,
        child: Text(
          widget.identifier,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontFamily: "Code",
              color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  Container buildBio(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.maxBioHeight),
              child: Scrollbar(
                thumbVisibility: true,
                controller: bioScrollController,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(0),
                  controller: bioScrollController,
                  child: widget.bio,
                ),
              ),
            )));
  }

  Widget userLocalTime() {
    final l = localTime!;
    var t = DateTime(l.year, l.month, l.day, l.hour, l.minute, l.second);

    var use24 = PlatformUtils.isAndroid
        ? MediaQuery.of(context).alwaysUse24HourFormat
        : false;
    var localDay = DateFormat(DateFormat.WEEKDAY).format(DateTime.now());
    var day = DateFormat(DateFormat.WEEKDAY).format(t);
    var time = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(t),
        alwaysUse24HourFormat: use24);

    var result = time;
    if (day != localDay) {
      result = "$day, $time";
    }

    final colors = Theme.of(context).colorScheme;
    return tiamat.Tooltip(
      child: TinyPill(result,
          background: colors.tertiary, foreground: colors.onTertiary),
      text: "Local Timezone: ${widget.timezone!}",
    );
  }

  List<tiamat.ContextMenuItem> contextMenuItems(BuildContext context) {
    return [
      if (widget.isSelf)
        tiamat.ContextMenuItem(
            text: "Change Banner",
            onPressed: () => widget.onSetBanner?.call(),
            icon: Icons.image),
      if (widget.isSelf)
        tiamat.ContextMenuItem(
            text: "Set Status",
            onPressed: () => widget.onSetStatus?.call(),
            icon: Icons.short_text),
      if (widget.isSelf)
        tiamat.ContextMenuItem(
            text: "Set Badges",
            onPressed: () => widget.editBadges?.call(),
            icon: Icons.star),
      if (widget.isSelf && widget.presence?.message != null)
        tiamat.ContextMenuItem(
            text: "Clear Status",
            onPressed: () => widget.clearStatus?.call(),
            icon: Icons.delete),
      if (widget.isSelf)
        tiamat.ContextMenuItem(
            text: "Set Bio",
            onPressed: () => widget.setBio?.call(),
            icon: Icons.text_snippet),
      if (widget.isSelf && widget.bio != null)
        tiamat.ContextMenuItem(
            text: "Clear Bio",
            onPressed: () => widget.clearBio?.call(),
            icon: Icons.delete),
      if (widget.isSelf)
        tiamat.ContextMenuItem(
            text: "Share Current Timezone",
            onPressed: () => widget.shareCurrentTimezone?.call(),
            icon: Icons.share_arrival_time),
      if (widget.isSelf && widget.timezone != null)
        tiamat.ContextMenuItem(
            text: "Remove Timezone",
            onPressed: () => widget.removeTimezone?.call(),
            icon: Icons.timer_off),
      if (widget.isSelf)
        tiamat.ContextMenuItem(
            text: "Edit Color Scheme",
            onPressed: () => setState(() {
                  editingColorScheme = true;
                }),
            icon: Icons.color_lens),
      tiamat.ContextMenuItem(
          text: "Set Color Override",
          onPressed: () async {
            var color = await AdaptiveDialog.show<Color>(
              title: "Color Override",
              context,
              builder: (context) {
                return SizedBox(
                  width: 500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: tiamat.Text.labelLow(
                            "Set a local color override for a user. This is only visible to you"),
                      ),
                      GridView(
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisSpacing: 3,
                                  mainAxisSpacing: 3,
                                  crossAxisCount: Layout.mobile ? 5 : 10),
                          children: [
                            for (int i = 0; i < 20; i++)
                              buildColorSchemeItem(
                                color: HSVColor.fromAHSV(1.0,
                                        (i.toDouble() / 21) * 360, 0.8, 1.0)
                                    .toColor(),
                                onTap: (c) {
                                  Navigator.of(context).pop(c);
                                },
                              )
                          ]),
                    ],
                  ),
                );
              },
            );

            if (color != null) {
              widget.setColorOverride?.call(color);
            }
          },
          icon: Icons.colorize),
      if (widget.hasColorOverride)
        tiamat.ContextMenuItem(
            text: "Clear Color Override",
            icon: Icons.remove,
            onPressed: () async {
              widget.setColorOverride?.call(null);
            }),
      if (preferences.developerMode)
        tiamat.ContextMenuItem(
            text: "Show Raw Profile",
            onPressed: () => widget.showSource?.call(),
            icon: Icons.code),
    ];
  }

  Widget buildColorSchemeEditor() {
    var run = 8;
    var count = run * 2;
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  GridView(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisSpacing: 3,
                        mainAxisSpacing: 3,
                        crossAxisCount: run),
                    children: [
                      for (int i = 0; i < count; i++)
                        buildColorSchemeItem(
                          color: HSVColor.fromAHSV(1.0,
                                  (i.toDouble() / (count + 1)) * 360, 0.5, 0.8)
                              .toColor(),
                          onTap: (c) => widget.setPreviewColor?.call(c),
                        ),
                      buildColorSchemeItem(
                          icon: Icons.light_mode,
                          onTap: (_) => widget.setPreviewBrightness
                              ?.call(Brightness.light)),
                      buildColorSchemeItem(
                          icon: Icons.dark_mode,
                          onTap: (_) => widget.setPreviewBrightness
                              ?.call(Brightness.dark)),
                      buildColorSchemeItem(
                        icon: Icons.tag,
                        onTap: (_) async {
                          var hexCode = await AdaptiveDialog.textPrompt(context,
                              title: "Enter Color Code", hintText: "#FFFFFF");
                          if (hexCode != null) {
                            var color = ColorUtils.fromHexCode(hexCode);
                            widget.setPreviewColor?.call(color);
                          }
                        },
                      ),
                      buildColorSchemeItem(
                        icon: Icons.save,
                        onTap: (_) {
                          widget.savePreviewTheme?.call();
                          setState(() {
                            editingColorScheme = false;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget buildColorSchemeItem({
    Color? color,
    IconData? icon,
    Function(Color)? onTap,
  }) {
    var c = color ?? Theme.of(context).colorScheme.primaryContainer;
    return Material(
      clipBehavior: Clip.antiAlias,
      color: c,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => onTap?.call(c),
        child: SizedBox(
          height: 30,
          width: 30,
          child: icon != null
              ? Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                )
              : null,
        ),
      ),
    );
  }

  Widget buildPresenceDisplay(Color background) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      child: Container(
          decoration: BoxDecoration(
              border: BoxBorder.all(color: background, width: 4),
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: tiamat.Text(
              widget.presence!.message!.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          )),
    );
  }

  Widget actionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        tiamat.Button(
          text: promptOpenDirectMessage,
          onTap: clickMessageButton,
          isLoading: isLoadingDirectMessage,
        ),
      ],
    );
  }

  Future<void> clickMessageButton() async {
    setState(() {
      isLoadingDirectMessage = true;
    });

    await widget.onMessageButtonClicked?.call();

    setState(() {
      isLoadingDirectMessage = false;
    });
  }

  Widget buildBadge(ProfileBadge i) {
    var doOutline = i.brightness == null
        ? false
        : Theme.of(context).brightness == i.brightness;

    return tiamat.Tooltip(
      text: i.body,
      child: SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            children: [
              if (doOutline)
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                        Theme.of(context)
                            .colorScheme
                            .inverseSurface
                            .withAlpha(200),
                        BlendMode.srcIn),
                    child: Image(
                      image: i.image,
                    ),
                  ),
                ),
              Image(
                image: i.image,
              ),
            ],
          )),
    );
  }

  Widget displayName() {
    return MouseRegion(
      cursor: widget.isSelf ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.isSelf ? widget.onChangeName : null,
        child: Text(
          widget.displayName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget pronouns() {
    if (widget.pronouns.isEmpty) return Container();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: widget.pronouns.map((i) => TinyPill(i)).toList(),
      ),
    );
  }

  Widget badges() {
    return Material(
      clipBehavior: Clip.hardEdge,
      borderRadius: BorderRadius.circular(8),
      color: widget.badges.isEmpty && widget.isSelf
          ? ColorScheme.of(context).surfaceContainerLow
          : Colors.transparent,
      child: InkWell(
        onTap: widget.isSelf ? () => widget.editBadges?.call() : null,
        child: Padding(
            padding: EdgeInsetsGeometry.fromLTRB(2, 2, 2, 2),
            child: Wrap(
              spacing: 8,
              children: widget.badges.map((i) => buildBadge(i)).toList(),
            )),
      ),
    );
  }
}
