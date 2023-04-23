import 'package:commet/client/client.dart';
import 'package:commet/client/preview_data.dart';
import 'package:commet/client/simulated/simulated_client.dart';
import 'package:commet/ui/atoms/room_preview.dart';
import 'package:commet/utils/debounce.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../../generated/l10n.dart';
import '../../molecules/account_selector.dart';

@WidgetbookUseCase(name: 'Multiple Accounts', type: AddSpaceView)
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
          content: AddSpaceView(
            clients: clients,
            initialPhase: AddSpacePhase.create,
          )));
}

@WidgetbookUseCase(name: 'Single Account', type: AddSpaceView)
@Deprecated("widgetbook")
Widget wbAddSpacePageSingleAccount(BuildContext context) {
  var clients = [SimulatedClient()];
  int index = 0;
  for (var client in clients) {
    client.login(LoginType.loginPassword, "simulatedClient${index++}", "");
  }
  return Scaffold(
      body: Tile(
    child: PopupDialog(
        title: "Add Space",
        content: AddSpaceView(
          clients: clients,
          initialPhase: AddSpacePhase.create,
        )),
  ));
}

class AddSpaceView extends StatefulWidget {
  const AddSpaceView(
      {super.key,
      required this.clients,
      this.onCreateSpace,
      this.onJoinSpace,
      this.initialPhase});
  final List<Client> clients;
  final Function(Client client, String spaceName, RoomVisibility visibility)?
      onCreateSpace;
  final Function(Client client, String address)? onJoinSpace;
  final AddSpacePhase? initialPhase;

  @override
  State<AddSpaceView> createState() => _AddSpaceViewState();
}

enum AddSpacePhase { askJoinOrCreate, create, join }

class _AddSpaceViewState extends State<AddSpaceView> {
  AddSpacePhase phase = AddSpacePhase.askJoinOrCreate;
  late Client selectedClient;
  RoomVisibility visibility = RoomVisibility.private;
  TextEditingController nameController = TextEditingController();
  TextEditingController topicController = TextEditingController();
  TextEditingController spaceAddressController = TextEditingController();

  PreviewData? spacePreview;
  bool loadingSpacePreview = false;

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
    selectedClient = widget.clients[0];

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
      height: 400,
      width: 400,
      child: Container(
          child: phase == AddSpacePhase.askJoinOrCreate
              ? promptJoinOrCreate(context)
              : phase == AddSpacePhase.join
                  ? joinSpace(context)
                  : phase == AddSpacePhase.create
                      ? createSpace(context)
                      : throw Exception("Impossible branch reached")),
    );
  }

  Widget userSelector() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: AccountSelector(
          widget.clients,
          onClientSelected: (client) {
            setState(() {
              selectedClient = client;
            });
          },
        ));
  }

  Widget createSpace(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.clients.length > 1) userSelector(),
          tiamat.TextInput(
            controller: nameController,
            placeholder: T.current.spaceNamePrompt,
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
              itemHeight: 104,
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
                    subtitle = T.current.roomVisibilityPublicExplanation;
                    break;
                  case RoomVisibility.private:
                  case RoomVisibility.invite:
                  case RoomVisibility.knock:
                    title = T.current.roomVisibilityPrivate;
                    icon = Icons.lock;
                    subtitle = T.current.roomVisibilityPrivateExplanation;
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
            child: tiamat.Button.success(
              text: T.current.addSpaceViewCreateSpaceButton,
              onTap: () => widget.onCreateSpace
                  ?.call(selectedClient, nameController.text, visibility),
            ),
          )
        ],
      ),
    );
  }

  Widget joinSpace(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.clients.length > 1) userSelector(),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tiamat.Text.label(T.of(context).spaceAddressPrompt),
              TextInput(
                controller: spaceAddressController,
                placeholder: "#awesome-space:example.com",
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
                    ? RoomPreview(previewData: spacePreview!)
                    : Center(
                        child: tiamat.Text.label(
                            T.of(context).couldNotLoadRoomPreview)),
          ),
          tiamat.Button.success(
            text: T.of(context).joinSpacePrompt,
            onTap: () {
              widget.onJoinSpace
                  ?.call(selectedClient, spaceAddressController.text);
            },
          ),
        ],
      ),
    );
  }

  Widget promptJoinOrCreate(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: InkWell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                  child: tiamat.Text.labelEmphasised(T.current.createNewSpace)),
            ),
            onTap: () {
              setState(() {
                phase = AddSpacePhase.create;
              });
            },
          ),
        ),
        const Seperator(),
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                phase = AddSpacePhase.join;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                  child:
                      tiamat.Text.labelEmphasised(T.current.joinExistingSpace)),
            ),
          ),
        )
      ],
    );
  }
}
