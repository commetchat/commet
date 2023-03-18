import 'package:commet/client/client.dart';
import 'package:commet/client/preview_data.dart';
import 'package:commet/client/simulated/simulated_client.dart';
import 'package:commet/ui/atoms/room_preview.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/pages/add_space/add_space.dart';
import 'package:commet/utils/debounce.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../../generated/l10n.dart';

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
            initialPhase: _AddSpacePhase.create,
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
      body: PopupDialog(
          title: "Add Space",
          content: AddSpaceView(
            clients: clients,
            initialPhase: _AddSpacePhase.create,
          )));
}

class AddSpaceView extends StatefulWidget {
  const AddSpaceView({super.key, required this.clients, this.onCreateSpace, this.onJoinSpace, this.initialPhase});
  final List<Client> clients;
  final Function(Client client, String spaceName, RoomVisibility visibility)? onCreateSpace;
  final Function(Client client, String address)? onJoinSpace;
  final _AddSpacePhase? initialPhase;

  @override
  State<AddSpaceView> createState() => _AddSpaceViewState();
}

enum _AddSpacePhase { askJoinOrCreate, create, join }

class _AddSpaceViewState extends State<AddSpaceView> {
  _AddSpacePhase phase = _AddSpacePhase.askJoinOrCreate;
  late Client selectedClient;
  RoomVisibility visibility = RoomVisibility.private;
  TextEditingController nameController = TextEditingController();
  TextEditingController topicController = TextEditingController();
  TextEditingController spaceAddressController = TextEditingController();

  PreviewData? spacePreview;
  bool loadingSpacePreview = false;

  Debouncer spacePreviewDebounce = Debouncer(delay: Duration(milliseconds: 500));

  void getSpacePreview() async {
    var preview = await selectedClient.getSpacePreview(spaceAddressController.text);

    setState(() {
      print("Got Preview");
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
          child: phase == _AddSpacePhase.askJoinOrCreate
              ? promptJoinOrCreate(context)
              : phase == _AddSpacePhase.join
                  ? joinSpace(context)
                  : phase == _AddSpacePhase.create
                      ? createSpace(context)
                      : throw Exception("Impossible branch reached")),
    );
  }

  Widget userSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: tiamat.DropdownSelector<Client>(
        items: widget.clients,
        itemHeight: 58,
        onItemSelected: (item) {
          setState(() {
            selectedClient = item;
          });
        },
        itemBuilder: (item) {
          return UserPanel(
            displayName: item.user!.displayName,
            detail: item.user!.detail,
            avatar: item.user!.avatar,
          );
        },
      ),
    );
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
              items: [RoomVisibility.private, RoomVisibility.public],
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
                          tiamat.Text.labelEmphasised(title),
                        ],
                      ),
                      tiamat.Text.label(
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
              onTap: () => widget.onCreateSpace?.call(selectedClient, nameController.text, visibility),
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
          Container(
            height: 100,
            child: loadingSpacePreview
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                    ],
                  )
                : spacePreview != null
                    ? RoomPreview(previewData: spacePreview!)
                    : Center(child: tiamat.Text.label(T.of(context).couldNotLoadRoomPreview)),
          ),
          tiamat.Button.success(
            text: T.of(context).joinSpacePrompt,
            onTap: () {
              widget.onJoinSpace?.call(selectedClient, spaceAddressController.text);
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
              child: Center(child: tiamat.Text.labelEmphasised(T.current.createNewSpace)),
            ),
            onTap: () {
              setState(() {
                phase = _AddSpacePhase.create;
              });
            },
          ),
        ),
        const Seperator(),
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                phase = _AddSpacePhase.join;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: tiamat.Text.labelEmphasised(T.current.joinExistingSpace)),
            ),
          ),
        )
      ],
    );
  }
}
