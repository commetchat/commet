import 'package:commet/client/client.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/ui/atoms/room_panel.dart';
import 'package:commet/ui/atoms/room_preview.dart';
import 'package:commet/ui/pages/add_space_or_room/add_space_or_room.dart';
import 'package:commet/utils/debounce.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../molecules/account_selector.dart';

class AddSpaceOrRoomView extends StatefulWidget {
  const AddSpaceOrRoomView(
      {super.key,
      this.client,
      this.clients,
      this.onCreate,
      this.onJoin,
      this.roomMode = false,
      this.rooms,
      this.loading = false,
      this.onRoomsSelected,
      this.initialPhase});
  final List<Client>? clients;
  final Client? client;
  final Function(Client client, CreateRoomArgs args)? onCreate;
  final Function(Client client, String address)? onJoin;
  final Function(Iterable<Room> selectedRooms)? onRoomsSelected;
  final AddSpaceOrRoomPhase? initialPhase;
  final bool roomMode;
  final bool loading;

  final List<Room>? rooms;

  @override
  State<AddSpaceOrRoomView> createState() => _AddSpaceOrRoomViewState();
}

enum AddSpaceOrRoomPhase {
  askJoinOrCreate,
  create,
  join,
  pickExisting,
  askCreateOrExisting
}

class _AddSpaceOrRoomViewState extends State<AddSpaceOrRoomView> {
  AddSpaceOrRoomPhase phase = AddSpaceOrRoomPhase.askJoinOrCreate;
  late Client selectedClient;
  RoomVisibility visibility = RoomVisibility.private;
  TextEditingController nameController = TextEditingController();
  TextEditingController topicController = TextEditingController();
  TextEditingController spaceAddressController = TextEditingController();
  GlobalKey<ToggleableListState> selectedRoomsState = GlobalKey();

  RoomPreview? spacePreview;
  bool loadingSpacePreview = false;
  bool enableE2EE = true;

  Debouncer spacePreviewDebounce =
      Debouncer(delay: const Duration(milliseconds: 500));

  String get promptRoomName => Intl.message("Room Name",
      name: "promptRoomName",
      desc: "Prompt to enter a room name, placeholder text for text input");

  String get promptSpaceName => Intl.message("Space Name",
      name: "promptSpaceName",
      desc: "Prompt to enter a space name, placeholder text for text input");

  String get promptTopic => Intl.message("Topic (Optional)",
      name: "promptTopic",
      desc:
          "Prompt to enter a topic for room or space, specifying that doing so is optional");

  String get roomVisibilityPrivateExplanation =>
      Intl.message("This room will only be accessible by invitation",
          name: "roomVisibilityPrivateExplanation",
          desc: "Explains what 'private' room visibility means");

  String get roomVisibilityPublicExplanation => Intl.message(
      "This room will be publically accessible by anyone on the internet",
      name: "roomVisibilityPublicExplanation",
      desc: "Explains what 'public' visibility means");

  String get spaceVisibilityPrivateExplanation =>
      Intl.message("This room will only be accessible by invitation",
          name: "spaceVisibilityPrivateExplanation",
          desc: "Explains what 'private' space visibility means");

  String get spaceVisibilityPublicExplanation => Intl.message(
      "This room will be publically accessible by anyone on the internet",
      name: "spaceVisibilityPublicExplanation",
      desc: "Explains what 'public' space visibility means");

  String get labelVisibilityPrivate => Intl.message("Private",
      name: "labelVisibilityPrivate",
      desc: "Short label for room visibility private");

  String get labelVisibilityPublic => Intl.message("Public",
      name: "labelVisibilityPublic",
      desc: "Short label for room visibility public");

  String get promptEnableEncryption => Intl.message("Enable Encryption",
      name: "promptEnableEncryption",
      desc: "Short prompt to enable encryption for a room");

  String get encryptionCannotBeDisabledExplanation =>
      Intl.message("If enabled, encryption cannot be disabled later",
          name: "encryptionCannotBeDisabledExplanation",
          desc: "Explains that encryption cannot be disabled once enabled");

  String get promptConfirmRoomCreation => Intl.message("Create Room!",
      name: "promptConfirmRoomCreation",
      desc: "Label for a button which confirms the creation of a room");

  String get promptConfirmSpaceCreation => Intl.message("Create Space!",
      name: "promptConfirmSpaceCreation",
      desc: "Label for a button which confirms the creation of a space");

  String get promptConfirmRoomJoin => Intl.message("Join Room!",
      name: "promptConfirmRoomJoin",
      desc: "Label for a button which confirms the joining of a room");

  String get promptConfirmSpaceJoin => Intl.message("Join Space!",
      name: "promptConfirmSpaceJoin",
      desc: "Label for a button which confirms the joining of a space");

  String get promptRoomAddress => Intl.message("Room Address:",
      name: "promptRoomAddress",
      desc: "Short label to prompt for the input of a room address");

  String get promptSpaceAddress => Intl.message("Space Address:",
      name: "promptSpaceAddress",
      desc: "Short label to prompt for the input of a space address");

  String get placeholderRoomAlias => Intl.message("#awesome-room",
      name: "placeholderRoomAlias",
      desc: "Placeholder / Example for a room alias.");

  String get placeholderSpaceAlias => Intl.message("#awesome-space",
      name: "placeholderSpaceAlias",
      desc: "Placeholder / Example for a space alias.");

  String get labelCouldNotLoadRoomPreview => Intl.message(
      "Could not load a preview of the room",
      name: "labelCouldNotLoadRoomPreview",
      desc: "Error message for when a room preview was not able to be loaded");

  String get promptAddSelectedRooms => Intl.message("Add selected rooms",
      name: "promptAddSelectedRooms",
      desc: "Prompt to add the selected rooms to a space");

  String get promptCreateNewSpace => Intl.message("Create new space",
      name: "promptCreateNewSpace", desc: "Prompt to create a new space");

  String get promptJoinExistingSpace => Intl.message("Join existing space",
      name: "promptJoinExistingSpace",
      desc: "Prompt to join a space which already exists");

  String get promptCreateNewRoom => Intl.message("Create new room",
      name: "promptCreateNewRoom", desc: "Prompt to create a new room");

  String get promptJoinExistingRoom => Intl.message("Join existing room",
      name: "promptJoinExistingRoom",
      desc: "Prompt to join a room which already exists");

  String get promptUseExistingRoom => Intl.message("Use existing room",
      name: "promptUseExistingRoom",
      desc:
          "Button text to choose to use an existing room when adding a room to a space");

  void getSpacePreview() async {
    var preview =
        await selectedClient.getSpacePreview(spaceAddressController.text);

    setState(() {
      spacePreview = preview;
      loadingSpacePreview = false;
    });
  }

  @override
  void initState() {
    selectedClient = widget.client ?? widget.clients![0];

    if (widget.initialPhase != null) phase = widget.initialPhase!;

    spaceAddressController.addListener(() {
      setState(() {
        loadingSpacePreview = true;
      });

      spacePreviewDebounce.run(getSpacePreview);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.loading,
      child: AnimatedOpacity(
        duration: Durations.short1,
        opacity: widget.loading ? 0.5 : 1.0,
        child: SizedBox(
          width: 400,
          child: Container(child: buildPhase(context)),
        ),
      ),
    );
  }

  Widget buildPhase(BuildContext context) {
    switch (phase) {
      case AddSpaceOrRoomPhase.askJoinOrCreate:
        if (widget.roomMode) return promptJoinOrCreateRoom(context);
        return promptJoinOrCreateSpace(context);
      case AddSpaceOrRoomPhase.create:
        return createSpace(context);
      case AddSpaceOrRoomPhase.join:
        return joinSpace(context);
      case AddSpaceOrRoomPhase.pickExisting:
        return pickExistingRoom(context);
      case AddSpaceOrRoomPhase.askCreateOrExisting:
        return promptCreateOrUseExisting(context);
    }
  }

  Widget userSelector() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: AccountSelector(
          widget.clients!,
          onClientSelected: (client) {
            setState(() {
              selectedClient = client;
            });
          },
        ));
  }

  Widget createSpace(BuildContext context) {
    return SizedBox(
      height: 450,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.client == null && widget.clients!.length > 1)
              userSelector(),
            tiamat.TextInput(
              controller: nameController,
              placeholder: widget.roomMode ? promptRoomName : promptSpaceName,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                child: tiamat.TextInput(
                  controller: topicController,
                  placeholder: promptTopic,
                  maxLines: 100,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
              child: tiamat.DropdownSelector<RoomVisibility>(
                items: const [RoomVisibility.private, RoomVisibility.public],
                itemHeight: 90,
                value: visibility,
                onItemSelected: (item) {
                  setState(() {
                    visibility = item;
                  });
                },
                itemBuilder: (item) {
                  String title;
                  IconData icon;
                  String subtitle;
                  switch (item) {
                    case RoomVisibility.public:
                      title = labelVisibilityPublic;
                      icon = Icons.public;
                      subtitle = widget.roomMode
                          ? roomVisibilityPublicExplanation
                          : spaceVisibilityPublicExplanation;
                      break;
                    case RoomVisibility.private:
                    case RoomVisibility.invite:
                    case RoomVisibility.knock:
                      title = labelVisibilityPrivate;
                      icon = Icons.lock;
                      subtitle = widget.roomMode
                          ? roomVisibilityPrivateExplanation
                          : spaceVisibilityPrivateExplanation;
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                              child: Icon(icon),
                            ),
                            tiamat.Text.label(title),
                          ],
                        ),
                        tiamat.Text.labelLow(
                          subtitle,
                          overflow: TextOverflow.fade,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (selectedClient.supportsE2EE)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          tiamat.Text.labelEmphasised(promptEnableEncryption),
                          tiamat.Text.labelLow(
                              encryptionCannotBeDisabledExplanation)
                        ],
                      ),
                    ),
                    tiamat.Switch(
                      state: enableE2EE,
                      onChanged: (value) {
                        setState(() {
                          enableE2EE = value;
                        });
                      },
                    )
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
              child: tiamat.Button.success(
                isLoading: widget.loading,
                text: widget.roomMode
                    ? promptConfirmRoomCreation
                    : promptConfirmSpaceCreation,
                onTap: () => widget.onCreate?.call(
                    selectedClient,
                    CreateRoomArgs(
                      name: nameController.text,
                      visibility: visibility,
                      enableE2EE: enableE2EE,
                    )),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget joinSpace(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.client == null && widget.clients!.length > 1)
              userSelector(),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tiamat.Text.label(
                    widget.roomMode ? promptRoomAddress : promptSpaceAddress),
                TextInput(
                  controller: spaceAddressController,
                  placeholder: widget.roomMode
                      ? "$placeholderRoomAlias:example.com"
                      : "$placeholderSpaceAlias:example.com",
                ),
              ],
            ),
            SizedBox(
              height: 100,
              child: loadingSpacePreview
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                      ],
                    )
                  : spacePreview != null
                      ? RoomPreviewView(previewData: spacePreview!)
                      : Center(
                          child:
                              tiamat.Text.label(labelCouldNotLoadRoomPreview)),
            ),
            tiamat.Button.success(
              isLoading: widget.loading,
              text: widget.roomMode
                  ? promptConfirmRoomJoin
                  : promptConfirmSpaceJoin,
              onTap: () {
                widget.onJoin
                    ?.call(selectedClient, spaceAddressController.text);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget pickExistingRoom(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 350),
          child: ToggleableList(
            key: selectedRoomsState,
            itemCount: widget.rooms!.length,
            itemBuilder: (context, index) {
              var room = widget.rooms![index];
              return Expanded(
                child: RoomPanel(
                  displayName: room.displayName,
                  avatar: room.avatar,
                  color: room.defaultColor,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: tiamat.Button(
            text: promptAddSelectedRooms,
            isLoading: widget.loading,
            onTap: () {
              if (selectedRoomsState.currentState != null) {
                widget.onRoomsSelected?.call(selectedRoomsState
                    .currentState!.selectedIndicies
                    .map((i) => widget.rooms![i]));
              }
            },
          ),
        )
      ],
    );
  }

  Widget promptJoinOrCreateSpace(BuildContext context) {
    return buildTwoChoicePrompt(context,
        option1: promptCreateNewSpace,
        option2: promptJoinExistingSpace, onOption1Tap: () {
      setState(() {
        phase = AddSpaceOrRoomPhase.create;
      });
    }, onOption2Tap: () {
      setState(() {
        phase = AddSpaceOrRoomPhase.join;
      });
    });
  }

  Widget promptJoinOrCreateRoom(BuildContext context) {
    return buildTwoChoicePrompt(context,
        option1: promptCreateNewRoom,
        option2: promptJoinExistingRoom, onOption1Tap: () {
      setState(() {
        phase = AddSpaceOrRoomPhase.create;
      });
    }, onOption2Tap: () {
      setState(() {
        phase = AddSpaceOrRoomPhase.join;
      });
    });
  }

  Widget promptCreateOrUseExisting(BuildContext context) {
    return buildTwoChoicePrompt(context,
        option1: promptCreateNewRoom,
        option2: promptUseExistingRoom, onOption1Tap: () {
      setState(() {
        phase = AddSpaceOrRoomPhase.create;
      });
    }, onOption2Tap: () {
      setState(() {
        phase = AddSpaceOrRoomPhase.pickExisting;
      });
    });
  }

  Widget buildTwoChoicePrompt(BuildContext context,
      {required String option1,
      required String option2,
      required Function() onOption1Tap,
      required Function() onOption2Tap}) {
    return SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: InkWell(
              onTap: onOption1Tap,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: tiamat.Text.labelEmphasised(option1),
                ),
              ),
            ),
          ),
          const Seperator(),
          Expanded(
            child: InkWell(
              onTap: onOption2Tap,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: tiamat.Text.labelEmphasised(option2)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
