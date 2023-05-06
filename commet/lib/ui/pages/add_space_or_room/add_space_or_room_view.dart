import 'package:commet/client/client.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/client/simulated/simulated_client.dart';
import 'package:commet/client/simulated/simulated_room.dart';
import 'package:commet/ui/atoms/room_panel.dart';
import 'package:commet/ui/atoms/room_preview.dart';
import 'package:commet/utils/debounce.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/toggleable_list.dart';

import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../../generated/l10n.dart';
import '../../molecules/account_selector.dart';

@WidgetbookUseCase(
    name: 'Add Space Multiple Accounts', type: AddSpaceOrRoomView)
@Deprecated("widgetbook")
Widget wbAddSpacePageMultiAccount(BuildContext context) {
  var clients = [SimulatedClient(), SimulatedClient(), SimulatedClient()];
  int index = 0;
  for (var client in clients) {
    client.login(LoginType.loginPassword, "simulatedClient${index++}", "");
  }
  return Scaffold(
      body: PopupDialog(
          title: "Add Space",
          content: AddSpaceOrRoomView(
            clients: clients,
            initialPhase: AddSpaceOrRoomPhase.create,
          )));
}

@WidgetbookUseCase(name: 'Add Space Single Account', type: AddSpaceOrRoomView)
@Deprecated("widgetbook")
Widget wbAddSpacePageSingleAccount(BuildContext context) {
  var client = SimulatedClient();
  client.login(LoginType.loginPassword, "simulatedClient", "");

  return Scaffold(
      body: Tile(
    child: PopupDialog(
        title: "Add Space",
        content: AddSpaceOrRoomView(
          client: client,
          initialPhase: AddSpaceOrRoomPhase.create,
        )),
  ));
}

@WidgetbookUseCase(name: 'Ask add space', type: AddSpaceOrRoomView)
@Deprecated("widgetbook")
Widget wbAddSpacePagePrompt(BuildContext context) {
  var client = SimulatedClient();
  client.login(LoginType.loginPassword, "simulatedClient", "");

  return Scaffold(
      body: Tile(
    child: PopupDialog(
        title: "Add Space",
        content: AddSpaceOrRoomView(
          client: client,
          initialPhase: AddSpaceOrRoomPhase.askJoinOrCreate,
        )),
  ));
}

@WidgetbookUseCase(name: 'Ask add room', type: AddSpaceOrRoomView)
@Deprecated("widgetbook")
Widget wbAddRoomPagePrompt(BuildContext context) {
  var clients = [SimulatedClient()];
  int index = 0;
  for (var client in clients) {
    client.login(LoginType.loginPassword, "simulatedClient${index++}", "");
  }
  return Scaffold(
      body: Tile(
    child: PopupDialog(
        title: "Add Room",
        content: AddSpaceOrRoomView(
          clients: clients,
          roomMode: true,
          initialPhase: AddSpaceOrRoomPhase.askJoinOrCreate,
        )),
  ));
}

@WidgetbookUseCase(name: 'Join Space', type: AddSpaceOrRoomView)
@Deprecated("widgetbook")
Widget wbAddRoomJoinSpace(BuildContext context) {
  var client = SimulatedClient();

  client.login(LoginType.loginPassword, "simulatedClient", "");

  return Scaffold(
      body: Tile(
    child: PopupDialog(
        title: "Add Space",
        content: AddSpaceOrRoomView(
          client: client,
          initialPhase: AddSpaceOrRoomPhase.join,
        )),
  ));
}

@WidgetbookUseCase(name: 'Join Room', type: AddSpaceOrRoomView)
@Deprecated("widgetbook")
Widget wbAddRoomJoinRoom(BuildContext context) {
  var client = SimulatedClient();

  client.login(LoginType.loginPassword, "simulatedClient", "");

  return Scaffold(
      body: Tile(
    child: PopupDialog(
        title: "Add Room",
        content: AddSpaceOrRoomView(
          client: client,
          roomMode: true,
          initialPhase: AddSpaceOrRoomPhase.join,
        )),
  ));
}

@WidgetbookUseCase(name: 'Add Room Single Account', type: AddSpaceOrRoomView)
@Deprecated("widgetbook")
Widget wbAddRoomPageSingleAccount(BuildContext context) {
  var client = SimulatedClient();
  client.login(LoginType.loginPassword, "simulatedClient", "");

  return Scaffold(
      body: Tile(
    child: PopupDialog(
        title: "Add Room",
        content: AddSpaceOrRoomView(
          client: client,
          initialPhase: AddSpaceOrRoomPhase.create,
          roomMode: true,
        )),
  ));
}

@WidgetbookUseCase(name: 'Add Room Multi Account', type: AddSpaceOrRoomView)
@Deprecated("widgetbook")
Widget wbAddRoomPageMultiAccount(BuildContext context) {
  var clients = [SimulatedClient(), SimulatedClient(), SimulatedClient()];
  int index = 0;
  for (var client in clients) {
    client.login(LoginType.loginPassword, "simulatedClient${index++}", "");
  }
  return Scaffold(
      body: Tile(
    child: PopupDialog(
        title: "Add Room",
        content: AddSpaceOrRoomView(
          clients: clients,
          initialPhase: AddSpaceOrRoomPhase.create,
          roomMode: true,
        )),
  ));
}

@WidgetbookUseCase(
    name: 'Ask create or use existing room', type: AddSpaceOrRoomView)
@Deprecated("widgetbook")
Widget wbAddRoomPromptUseOrCreateMultiAccount(BuildContext context) {
  var client = SimulatedClient();
  client.login(LoginType.loginPassword, "simulatedClient", "");
  return Scaffold(
      body: Tile(
    child: PopupDialog(
        title: "Add Room",
        content: AddSpaceOrRoomView(
          client: client,
          initialPhase: AddSpaceOrRoomPhase.askCreateOrExisting,
          roomMode: true,
        )),
  ));
}

@WidgetbookUseCase(name: 'Pick existing room', type: AddSpaceOrRoomView)
@Deprecated("widgetbook")
Widget wbAddRoomPickExistingRoom(BuildContext context) {
  var client = SimulatedClient();
  client.login(LoginType.loginPassword, "simulatedClient", "");

  return Scaffold(
      body: Tile(
    child: PopupDialog(
        title: "Add Room",
        content: AddSpaceOrRoomView(
          client: client,
          initialPhase: AddSpaceOrRoomPhase.pickExisting,
          roomMode: true,
          rooms: [
            SimulatedRoom("Room 1", client),
            SimulatedRoom("Room 2", client),
            SimulatedRoom("Room 3", client),
            SimulatedRoom("Room 4", client),
            SimulatedRoom("Room 5", client),
            SimulatedRoom("Room 6", client),
            SimulatedRoom("Room 7", client),
            SimulatedRoom("Room 8", client),
            SimulatedRoom("Room 9", client),
            SimulatedRoom("Room 10", client),
            SimulatedRoom("Room 11", client),
            SimulatedRoom("Room 12", client),
          ],
        )),
  ));
}

class AddSpaceOrRoomView extends StatefulWidget {
  const AddSpaceOrRoomView(
      {super.key,
      this.client,
      this.clients,
      this.onCreate,
      this.onJoin,
      this.roomMode = false,
      this.rooms,
      this.onRoomsSelected,
      this.initialPhase});
  final List<Client>? clients;
  final Client? client;
  final Function(Client client, String name, RoomVisibility visibility,
      bool enableE2EE)? onCreate;
  final Function(Client client, String address)? onJoin;
  final Function(Iterable<Room> selectedRooms)? onRoomsSelected;
  final AddSpaceOrRoomPhase? initialPhase;
  final bool roomMode;

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
    return SizedBox(
      width: 400,
      child: Container(child: buildPhase(context)),
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
              placeholder: widget.roomMode
                  ? T.current.roomNamePrompt
                  : T.current.spaceNamePrompt,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                child: tiamat.TextInput(
                  controller: topicController,
                  placeholder: T.current.spaceTopicPrompt,
                  maxLines: 100,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
              child: tiamat.DropdownSelector<RoomVisibility>(
                items: const [RoomVisibility.private, RoomVisibility.public],
                itemHeight: 90,
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
                      title = T.current.roomVisibilityPublic;
                      icon = Icons.public;
                      subtitle = widget.roomMode
                          ? T.current.roomVisibilityPublicExplanation
                          : T.current.spaceVisibilityPublicExplanation;
                      break;
                    case RoomVisibility.private:
                    case RoomVisibility.invite:
                    case RoomVisibility.knock:
                      title = T.current.roomVisibilityPrivate;
                      icon = Icons.lock;
                      subtitle = widget.roomMode
                          ? T.current.roomVisibilityPrivateExplanation
                          : T.current.spaceVisibilityPrivateExplanation;
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
                          tiamat.Text.labelEmphasised(
                              T.current.enableEncryptionPrompt),
                          tiamat.Text.labelLow(
                              T.current.encryptionCannotBeDisabled)
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
                text: widget.roomMode
                    ? T.current.addSpaceViewCreateRoomButton
                    : T.current.addSpaceViewCreateSpaceButton,
                onTap: () => widget.onCreate?.call(selectedClient,
                    nameController.text, visibility, enableE2EE),
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
                tiamat.Text.label(widget.roomMode
                    ? T.current.roomAddressPrompt
                    : T.current.spaceAddressPrompt),
                TextInput(
                  controller: spaceAddressController,
                  placeholder: widget.roomMode
                      ? "#awesome-room:example.com"
                      : "#awesome-space:example.com",
                ),
              ],
            ),
            SizedBox(
              height: 100,
              child: loadingSpacePreview
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(),
                      ],
                    )
                  : spacePreview != null
                      ? RoomPreviewView(previewData: spacePreview!)
                      : Center(
                          child: tiamat.Text.label(
                              T.current.couldNotLoadRoomPreview)),
            ),
            tiamat.Button.success(
              text: widget.roomMode
                  ? T.current.joinRoomPrompt
                  : T.current.joinSpacePrompt,
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
              return RoomPanel(
                displayName: room.displayName,
                avatar: room.avatar,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: tiamat.Button(
            text: "Add Selected Rooms",
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
        option1: T.current.createNewSpace,
        option2: T.current.joinExistingSpace, onOption1Tap: () {
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
        option1: "Create New room",
        option2: "Join existing room", onOption1Tap: () {
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
        option1: "Create New room",
        option2: "Use existing room", onOption1Tap: () {
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