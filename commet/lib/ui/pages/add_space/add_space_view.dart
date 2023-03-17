import 'package:commet/client/client.dart';
import 'package:commet/ui/molecules/user_panel.dart';
import 'package:commet/ui/pages/add_space/add_space.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../../generated/l10n.dart';

class AddSpaceView extends StatefulWidget {
  const AddSpaceView({super.key, required this.clients, this.onCreateSpace});
  final List<Client> clients;
  final Function(Client client, String spaceName, RoomVisibility visibility)? onCreateSpace;

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

  @override
  void initState() {
    selectedClient = widget.clients[0];
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

  Widget createSpace(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.clients.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: tiamat.DropdownSelector<Client>(
                items: widget.clients,
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
            ),
          tiamat.TextInput(
            controller: nameController,
            placeholder: T.of(context).spaceNamePrompt,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: tiamat.TextInput(
                controller: topicController,
                label: T.of(context).spaceTopicPrompt,
                maxLines: 100,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: tiamat.DropdownSelector<RoomVisibility>(
              items: [RoomVisibility.private, RoomVisibility.public],
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
                    title = T.of(context).roomVisibilityPublic;
                    icon = Icons.public;
                    subtitle = T.of(context).roomVisibilityPublicExplanation;
                    break;
                  case RoomVisibility.private:
                    title = T.of(context).roomVisibilityPrivate;
                    icon = Icons.lock;
                    subtitle = T.of(context).roomVisibilityPrivateExplanation;
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                        child: SizedBox(width: 340, child: tiamat.Text.label(subtitle)),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
            child: tiamat.Button.success(
              text: T.of(context).addSpaceViewCreateSpaceButton,
              onTap: () => widget.onCreateSpace?.call(selectedClient, nameController.text, visibility),
            ),
          )
        ],
      ),
    );
  }

  Widget joinSpace(BuildContext context) {
    return Placeholder();
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
