import 'package:commet/client/client.dart';
import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/invitation/invitation_component.dart';
import 'package:commet/client/space_child.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/invitation_view/send_invitation.dart';
import 'package:commet/ui/pages/get_or_create_room/calendar_views.dart';
import 'package:commet/ui/pages/get_or_create_room/existing_room_picker.dart';
import 'package:commet/ui/pages/get_or_create_room/join_room_view.dart';
import 'package:commet/ui/pages/get_or_create_room/photo_album_views.dart';
import 'package:commet/ui/pages/get_or_create_room/room_creator.dart';
import 'package:commet/ui/pages/get_or_create_room/space_views.dart';
import 'package:commet/ui/pages/get_or_create_room/text_chat_views.dart';
import 'package:commet/ui/pages/get_or_create_room/voice_chat_view.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomGetter {
  final String label;
  final IconData icon;
  final Widget Function(BuildContext context) descriptionBuilder;
  final Widget Function(BuildContext context, {Function(SpaceChild)? onPicked})
      formBuilder;

  final Future<SpaceChild> Function(CreateRoomArgs args)? create;
  final bool hero;

  const RoomGetter({
    required this.label,
    required this.icon,
    this.hero = false,
    required this.descriptionBuilder,
    required this.formBuilder,
    this.create,
  });
}

enum _RoomSourceOptions { create, existing, startdm, join }

class GetOrCreateRoom extends StatefulWidget {
  const GetOrCreateRoom(
      {super.key, required this.creators, this.existing, this.dm, this.join});

  final List<RoomGetter> creators;
  final RoomGetter? existing;
  final RoomGetter? dm;
  final RoomGetter? join;

  static Future<SpaceChild?> show(
    Client? client,
    BuildContext context, {
    bool startdm = false,
    bool joinRoom = true,
    bool pickExisting = true,
    bool showAllRoomTypes = false,
    bool createSpace = false,
    bool createTextChat = false,
    bool createVoiceChat = false,
    bool createPhotoRoom = false,
    bool createCalendar = false,
    String? initialRoomAddress,
    Space? currentSpace,
    bool Function(SpaceChild child)? existingRoomsRemoveWhere,
  }) async {
    if (client == null) {
      client = await AdaptiveDialog.pickClient(
        context,
      );
    }

    if (client == null) {
      return null;
    }

    final creators = [
      if (showAllRoomTypes || createTextChat)
        RoomGetter(
          label: "Text Chat",
          icon: Icons.tag,
          descriptionBuilder: (context) => TextChatCreatorDescription(),
          formBuilder: (context, {onPicked}) => RoomCreatorWidget(
            fields: [
              RoomFieldName(),
              RoomFieldTopic(),
              RoomFieldVisibility(client: client!, currentSpace: currentSpace),
              RoomFieldEncryption(
                  canEnableEncryption: true, defaultEnabled: true),
            ],
          ),
          create: (args) async {
            return SpaceChildRoom(await client!.createRoom(args));
          },
        ),
      if ((showAllRoomTypes || createVoiceChat))
        RoomGetter(
          label: "Voice Chat",
          icon: Icons.volume_up,
          descriptionBuilder: (context) => VoiceChatCreatorDescription(),
          formBuilder: (context, {onPicked}) => RoomCreatorWidget(
            fields: [
              RoomFieldName(),
              RoomFieldTopic(),
              RoomFieldVisibility(client: client!, currentSpace: currentSpace),
              RoomFieldEncryption(
                  canEnableEncryption: false, defaultEnabled: false),
              RoomFieldType(RoomType.voipRoom),
            ],
          ),
          create: (args) async {
            return SpaceChildRoom(await client!.createRoom(args));
          },
        ),
      if ((showAllRoomTypes || createPhotoRoom))
        RoomGetter(
          label: "Photo Album",
          icon: Icons.photo,
          descriptionBuilder: (context) => PhotoAlbumCreatorDescription(),
          formBuilder: (context, {onPicked}) => RoomCreatorWidget(
            fields: [
              RoomFieldName(),
              RoomFieldTopic(),
              RoomFieldVisibility(client: client!, currentSpace: currentSpace),
              RoomFieldEncryption(defaultEnabled: true),
              RoomFieldType(RoomType.photoAlbum),
            ],
          ),
          create: (args) async {
            return SpaceChildRoom(await client!.createRoom(args));
          },
        ),
      if ((showAllRoomTypes || createCalendar))
        RoomGetter(
          label: "Calendar",
          icon: Icons.calendar_month,
          descriptionBuilder: (context) => CalendarCreatorDescription(),
          formBuilder: (context, {onPicked}) => RoomCreatorWidget(
            fields: [
              RoomFieldName(),
              RoomFieldTopic(),
              RoomFieldVisibility(client: client!, currentSpace: currentSpace),
              RoomFieldEncryption(defaultEnabled: true),
              RoomFieldType(RoomType.calendar),
            ],
          ),
          create: (args) async {
            return SpaceChildRoom(await client!.createRoom(args));
          },
        ),
      if (showAllRoomTypes || createSpace)
        RoomGetter(
          label: "Space",
          icon: Icons.spoke,
          descriptionBuilder: (context) => SpaceCreatorDescription(),
          formBuilder: (context, {onPicked}) => RoomCreatorWidget(
            fields: [
              RoomFieldName(),
              RoomFieldTopic(),
              RoomFieldVisibility(client: client!, currentSpace: currentSpace),
            ],
          ),
          create: (args) async {
            return SpaceChildSpace(await client!.createSpace(args));
          },
        ),
    ];

    final existing = pickExisting
        ? RoomGetter(
            label: "Existing Room",
            hero: true,
            icon: Icons.add,
            descriptionBuilder: (_) => Placeholder(),
            formBuilder: (context, {onPicked}) => ExistingRoomPicker(
              client: client!,
              filter: existingRoomsRemoveWhere,
              onPicked: onPicked,
            ),
          )
        : null;

    final dm = startdm
        ? RoomGetter(
            label: "Start Direct Message",
            hero: true,
            icon: Icons.message,
            descriptionBuilder: (_) => Placeholder(),
            formBuilder: (context, {onPicked}) {
              final invitation = client?.getComponent<InvitationComponent>();
              if (invitation == null) return Placeholder();

              return SendInvitationWidget(
                client!,
                invitation,
                showSuggestions: false,
                embedded: true,
                onUserPicked: (userId) async {
                  final confirm = await AdaptiveDialog.confirmation(context,
                      prompt:
                          "Are you sure you want to invite $userId to chat?",
                      title: "Invitation");
                  if (confirm != true) {
                    return;
                  }

                  var comp = client!.getComponent<DirectMessagesComponent>();
                  var room = await comp?.createDirectMessage(userId);

                  if (room != null) onPicked!(SpaceChildRoom(room));
                },
              );
            },
          )
        : null;

    final join = joinRoom
        ? RoomGetter(
            label: "Join Room",
            hero: true,
            icon: Icons.search,
            descriptionBuilder: (_) => Placeholder(),
            formBuilder: (context, {onPicked}) => JoinRoomView(
              client!,
              asSpace: false,
              onPicked: onPicked,
              initialRoomAddress: initialRoomAddress,
            ),
          )
        : null;

    if (Layout.mobile) {
      _RoomSourceOptions? source;
      if (initialRoomAddress != null) {
        source = _RoomSourceOptions.join;
      } else {
        source = await AdaptiveDialog.pickOne(context,
            items: [
              _RoomSourceOptions.create,
              if (existing != null) _RoomSourceOptions.existing,
              if (dm != null) _RoomSourceOptions.startdm,
              if (join != null) _RoomSourceOptions.join,
            ],
            itemBuilder: (context, item, callback) => SizedBox(
                  height: 50,
                  child: switch (item) {
                    _RoomSourceOptions.create => tiamat.TextButton(
                        "Create Room",
                        icon: Icons.add,
                        onTap: callback,
                      ),
                    _RoomSourceOptions.existing => tiamat.TextButton(
                        "Use Existing Room",
                        icon: Icons.tag,
                        onTap: callback,
                      ),
                    _RoomSourceOptions.startdm => tiamat.TextButton(
                        "Start Direct Message",
                        icon: Icons.message,
                        onTap: callback,
                      ),
                    _RoomSourceOptions.join => tiamat.TextButton(
                        "Join Room",
                        icon: Icons.alternate_email,
                        onTap: callback,
                      ),
                  },
                ));
      }

      if (source == _RoomSourceOptions.create) {
        return AdaptiveDialog.show<SpaceChild>(
          context,
          scrollable: false,
          builder: (context) {
            return GetOrCreateRoom(
              creators: creators,
            );
          },
        );
      }

      if (source == _RoomSourceOptions.startdm) {
        return AdaptiveDialog.show<SpaceChild>(
          context,
          scrollable: false,
          builder: (context) {
            return dm!.formBuilder(context,
                onPicked: (i) => Navigator.of(context).pop(i));
          },
        );
      }

      if (source == _RoomSourceOptions.join) {
        return AdaptiveDialog.show<SpaceChild>(
          context,
          scrollable: false,
          builder: (context) {
            return join!.formBuilder(context,
                onPicked: (i) => Navigator.of(context).pop(i));
          },
        );
      }

      if (source == _RoomSourceOptions.existing) {
        return AdaptiveDialog.show<SpaceChild>(
          context,
          scrollable: false,
          builder: (context) {
            return SizedBox(
                height: 500,
                child: existing!.formBuilder(context,
                    onPicked: (i) => Navigator.of(context).pop(i)));
          },
        );
      }

      return null;
    }

    return AdaptiveDialog.show<SpaceChild>(
      context,
      scrollable: false,
      builder: (context) {
        return GetOrCreateRoom(
          creators: creators,
          existing: existing,
          dm: dm,
          join: join,
        );
      },
    );
  }

  @override
  State<GetOrCreateRoom> createState() => _GetOrCreateRoomState();
}

class _GetOrCreateRoomState extends State<GetOrCreateRoom> {
  RoomGetter? selected;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    if (widget.join != null) {
      selected = widget.join;
    } else if (widget.creators.isNotEmpty) {
      selected = widget.creators.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Layout.mobile)
      return IgnorePointer(
        ignoring: loading,
        child: Opacity(
          opacity: loading ? 0.5 : 1.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (widget.creators.length == 1)
                return SizedBox(
                  height: 500,
                  child: buildListViewEntry(
                      widget.creators.first, context, constraints.maxWidth),
                );

              return Container(
                child: ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(8),
                  child: SizedBox(
                      height: 500,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (var entry in widget.creators)
                            buildListViewEntry(
                                entry, context, constraints.maxWidth - 150)
                        ],
                      )),
                ),
              );
            },
          ),
        ),
      );

    return SizedBox(
      width: 800,
      height: 500,
      child: Stack(
        children: [
          IgnorePointer(
            ignoring: loading,
            child: Opacity(
              opacity: loading ? 0.5 : 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  SingleChildScrollView(
                    child: SizedBox(
                      width: 200,
                      child: Column(
                        spacing: 8,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.existing != null)
                            createEntry(widget.existing!),
                          if (widget.dm != null) createEntry(widget.dm!),
                          if (widget.join != null) createEntry(widget.join!),
                          if (widget.creators.isNotEmpty)
                            tiamat.Text.labelLow("Create Room:"),
                          for (var entry in widget.creators) createEntry(entry)
                        ],
                      ),
                    ),
                  ),
                  if (selected != null)
                    Flexible(
                        child: Container(
                      decoration: BoxDecoration(
                        color: ColorScheme.of(context).surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected!.label,
                              style: TextTheme.of(context).headlineSmall,
                            ),
                            if (!selected!.hero)
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: NeverScrollableScrollPhysics(),
                                  child: Padding(
                                    padding:
                                        EdgeInsetsGeometry.fromLTRB(0, 0, 0, 0),
                                    child:
                                        selected!.descriptionBuilder(context),
                                  ),
                                ),
                              ),
                            if (selected!.hero)
                              Expanded(
                                  child: selected!.formBuilder(
                                context,
                                onPicked: onExistingRoomPicked,
                              )),
                            if (!selected!.hero)
                              Align(
                                alignment: AlignmentGeometry.bottomRight,
                                child: tiamat.Button(
                                  text: "Next",
                                  onTap: () {
                                    onNextButtonPressed(selected!);
                                  },
                                ),
                              )
                          ],
                        ),
                      ),
                    ))
                ],
              ),
            ),
          ),
          if (loading)
            Center(
              child: CircularProgressIndicator(),
            )
        ],
      ),
    );
  }

  Widget buildListViewEntry(
      RoomGetter entry, BuildContext context, double width) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
      child: Container(
        decoration: BoxDecoration(
            color: ColorScheme.of(context).surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8)),
        child: SizedBox(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: TextTheme.of(context).headlineSmall,
                ),
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        end: Alignment(0, 0.7),
                        begin: Alignment(0, 1),
                        colors: [
                          Colors.purple,
                          Colors.transparent,
                        ],
                        stops: [
                          0.0,
                          1.0,
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstOut,
                    child: SingleChildScrollView(
                      physics: NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        width: width,
                        child: entry.descriptionBuilder(context),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 38, 0, 0),
                    child: tiamat.Button(
                      text: "Next",
                      isLoading: entry == selected && loading,
                      onTap: () => onNextButtonPressed(entry),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  SizedBox createEntry(RoomGetter entry) {
    return SizedBox(
      height: 50,
      child: tiamat.TextButton(
        entry.label,
        icon: entry.icon,
        highlighted: entry == selected,
        onTap: () {
          setState(() {
            selected = entry;
          });
        },
      ),
    );
  }

  onNextButtonPressed(RoomGetter entry) async {
    setState(() {
      selected = entry;
      loading = true;
    });

    var args = await AdaptiveDialog.show<CreateRoomArgs>(
      context,
      title: entry.label,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: entry.formBuilder(context),
        );
      },
    );

    setState(() {
      selected = entry;
      loading = true;
    });

    if (args != null) {
      try {
        var result = await entry.create!(args);

        print(result);

        Navigator.of(context).pop(result);
      } catch (e, s) {
        Log.onError(e, s);
        await AdaptiveDialog.show(
          context,
          title: "Error",
          builder: (context) {
            return tiamat.Text.body(e.toString());
          },
        );

        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  onExistingRoomPicked(SpaceChild result) {
    print("Existing picked: ${result}");
    Navigator.of(context).pop(result);
  }
}
