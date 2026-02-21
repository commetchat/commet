import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

abstract class RoomField {
  Widget build(CreateRoomArgs args, Function() onArgsChanged);

  void setDefaults(CreateRoomArgs args);

  bool isValid(CreateRoomArgs args);
}

class RoomFieldType implements RoomField {
  final RoomType type;

  RoomFieldType(this.type);

  @override
  Widget build(CreateRoomArgs args, Function() onArgsChanged) {
    return Container();
  }

  @override
  void setDefaults(CreateRoomArgs args) {
    args.roomType = type;
  }

  @override
  bool isValid(CreateRoomArgs args) {
    return args.roomType == type;
  }
}

class RoomFieldName implements RoomField {
  String get promptRoomName => Intl.message(
        "Room Name",
        name: "promptRoomName",
        desc: "Prompt to enter a room name, placeholder text for text input",
      );

  @override
  Widget build(CreateRoomArgs args, Function() onArgsChanged) {
    return TextField(
      onChanged: (value) {
        args.name = value;
        onArgsChanged();
      },
      decoration: InputDecoration(hint: tiamat.Text.labelLow(promptRoomName)),
    );
  }

  @override
  void setDefaults(CreateRoomArgs args) {}

  @override
  bool isValid(CreateRoomArgs args) {
    return args.name?.isNotEmpty == true;
  }
}

class RoomFieldTopic implements RoomField {
  String get promptTopic => Intl.message(
        "Topic (Optional)",
        name: "promptTopic",
        desc:
            "Prompt to enter a topic for room or space, specifying that doing so is optional",
      );

  @override
  Widget build(CreateRoomArgs args, Function() onArgsChanged) {
    return TextField(
      onChanged: (value) {
        args.topic = value;
        onArgsChanged();
      },
      maxLines: 3,
      decoration: InputDecoration(hint: tiamat.Text.labelLow(promptTopic)),
    );
  }

  @override
  void setDefaults(CreateRoomArgs args) {}

  @override
  bool isValid(CreateRoomArgs args) {
    return true;
  }
}

class RoomFieldEncryption implements RoomField {
  final bool canEnableEncryption;
  final bool defaultEnabled;

  String get promptEnableEncryption => Intl.message(
        "Enable Encryption",
        name: "promptEnableEncryption",
        desc: "Short prompt to enable encryption for a room",
      );

  String get encryptionCannotBeDisabledExplanation => Intl.message(
        "If enabled, encryption cannot be disabled later",
        name: "encryptionCannotBeDisabledExplanation",
        desc: "Explains that encryption cannot be disabled once enabled",
      );

  RoomFieldEncryption(
      {required this.defaultEnabled, this.canEnableEncryption = true});

  @override
  Widget build(CreateRoomArgs args, Function() onArgsChanged) {
    Widget result = IgnorePointer(
      ignoring: canEnableEncryption == false,
      child: Opacity(
        opacity: canEnableEncryption ? 1 : 0.5,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tiamat.Text.label(promptEnableEncryption),
                tiamat.Text.labelLow(encryptionCannotBeDisabledExplanation)
              ],
            ),
            tiamat.Switch(
              state: args.enableE2EE == true,
              onChanged: (value) {
                args.enableE2EE = value;
                onArgsChanged();
              },
            )
          ],
        ),
      ),
    );

    if (!canEnableEncryption) {
      result = tiamat.Tooltip(
          child: result,
          text: "Sorry, Encryption is not yet supported on this type of room");
    }

    return result;
  }

  @override
  void setDefaults(CreateRoomArgs args) {
    args.enableE2EE = defaultEnabled;
  }

  @override
  bool isValid(CreateRoomArgs args) {
    return args.enableE2EE != null;
  }
}

class RoomFieldVisibility implements RoomField {
  Space? currentSpace;

  RoomFieldVisibility({this.currentSpace});

  String get roomVisibilityPrivateExplanation => Intl.message(
        "This room will only be accessible by invitation",
        name: "roomVisibilityPrivateExplanation",
        desc: "Explains what 'private' room visibility means",
      );

  String get roomVisibilityPublicExplanation => Intl.message(
        "This room will be publically accessible by anyone on the internet",
        name: "roomVisibilityPublicExplanation",
        desc: "Explains what 'public' visibility means",
      );

  String get labelVisibilityPrivate => Intl.message(
        "Private",
        name: "labelVisibilityPrivate",
        desc: "Short label for room visibility private",
      );

  String get labelVisibilityPublic => Intl.message(
        "Public",
        name: "labelVisibilityPublic",
        desc: "Short label for room visibility public",
      );

  String get roomVisibilityRestrictedExplanation => Intl.message(
        "This room will be available to anyone who is a member of it's parent spaces",
        name: "roomVisibilityRestrictedExplanation",
        desc: "Explains what 'restricted' visibility means",
      );

  String get labelVisibilityRestricted => Intl.message(
        "Restricted",
        name: "labelVisibilityRestricted",
        desc: "Short label for room visibility restricted",
      );

  @override
  void setDefaults(CreateRoomArgs args) {
    if (currentSpace != null) {
      args.visibility = RoomVisibilityRestricted([currentSpace!.identifier]);
    } else {
      args.visibility = RoomVisibilityPrivate();
    }
  }

  @override
  bool isValid(CreateRoomArgs args) {
    return args.visibility != null;
  }

  @override
  Widget build(CreateRoomArgs args, Function() onArgsChanged) {
    return SizedBox(
      height: 90,
      child: tiamat.DropdownSelector<RoomVisibility?>(
        itemHeight: 80,
        value: args.visibility,
        items: [
          RoomVisibilityPrivate(),
          RoomVisibilityPublic(),
          if (currentSpace != null)
            RoomVisibilityRestricted([currentSpace!.identifier])
        ],
        onItemSelected: (item) {
          args.visibility = item;
          onArgsChanged();
        },
        itemBuilder: (item) {
          String? title;
          Widget icon = Icon(RoomVisibility.icon(item));
          String? subtitle;
          switch (item) {
            case final RoomVisibilityPublic _:
              title = labelVisibilityPublic;
              subtitle = roomVisibilityPublicExplanation;
              break;
            case final RoomVisibilityPrivate _:
              title = labelVisibilityPrivate;
              subtitle = roomVisibilityPrivateExplanation;
              break;
            case final RoomVisibilityRestricted restricted:
              title = labelVisibilityRestricted;
              subtitle = roomVisibilityRestrictedExplanation;

              icon =
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                for (var i in restricted.spaces) buildSpaceIcon(i),
              ]);
              break;
            case null:
              break;
          }

          return Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 2, 8, 0),
                        child: icon,
                      ),
                      tiamat.Text.label(title!),
                    ],
                  ),
                ),
                tiamat.Text.labelLow(
                  subtitle!,
                  overflow: TextOverflow.fade,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildSpaceIcon(String i) {
    var client = currentSpace?.client;

    Space? space = client?.getSpace(i);

    return tiamat.Tooltip(
      text: space?.displayName ?? i,
      child: tiamat.Avatar(
          radius: 13,
          image: space?.avatar,
          placeholderText: space?.displayName ?? i,
          placeholderColor: space?.color ?? MatrixPeer.hashColor(i)),
    );
  }
}

class RoomCreatorWidget extends StatefulWidget {
  const RoomCreatorWidget({required this.fields, super.key});

  final List<RoomField> fields;

  @override
  State<RoomCreatorWidget> createState() => _RoomCreatorWidgetState();
}

class _RoomCreatorWidgetState extends State<RoomCreatorWidget> {
  CreateRoomArgs args = CreateRoomArgs();
  bool valid = false;

  String get promptConfirmRoomCreation => Intl.message(
        "Create Room!",
        name: "promptConfirmRoomCreation",
        desc: "Label for a button which confirms the creation of a room",
      );

  @override
  void initState() {
    for (var entry in widget.fields) entry.setDefaults(args);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Layout.desktop ? 500 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          for (var entry in widget.fields) entry.build(args, onArgsChanged),
          IgnorePointer(
            ignoring: !valid,
            child: Opacity(
              opacity: valid ? 1 : 0.4,
              child: tiamat.Button(
                text: promptConfirmRoomCreation,
                onTap: () {
                  Navigator.of(context).pop(args);
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  void onArgsChanged() {
    bool isValid = true;

    for (var entry in widget.fields) {
      isValid = isValid && entry.isValid(args);
    }

    setState(() {
      valid = isValid;
    });

    print(args);
  }
}
