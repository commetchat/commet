import 'package:commet/ui/atoms/tooltip.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as material;

class ProfileEditView extends StatefulWidget {
  const ProfileEditView(
      {super.key,
      required this.avatar,
      required this.displayName,
      required this.identifier,
      this.pickAvatar,
      this.setDisplayName});
  final ImageProvider? avatar;
  final String displayName;
  final String identifier;
  final Function? pickAvatar;
  final Function(String name)? setDisplayName;

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  bool editingName = false;
  late TextEditingController nameController;
  late String displayName;

  @override
  void initState() {
    displayName = widget.displayName;
    nameController = TextEditingController(text: displayName);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatarEditor(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [nameEditor(), toggleNameEdit()],
                ),
                tiamat.Text.labelLow(widget.identifier),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget avatarEditor() {
    return Tooltip(
      text: "Edit Avatar",
      preferredDirection: AxisDirection.down,
      child: ImageButton(
        size: 128,
        image: widget.avatar,
        onTap: () => widget.pickAvatar?.call(),
      ),
    );
  }

  Widget nameEditor() {
    return editingName
        ? SizedBox(
            width: 200,
            child: TextInput(
              maxLines: 1,
              controller: nameController,
            ),
          )
        : tiamat.Text.largeTitle(displayName);
  }

  Widget toggleNameEdit() {
    return editingName
        ? Tooltip(
            text: "Confirm",
            preferredDirection: AxisDirection.right,
            child: tiamat.IconButton(
              icon: material.Icons.check,
              onPressed: () {
                var name = nameController.text.trim();
                if (name.isEmpty) return;

                widget.setDisplayName?.call(name);

                setState(() {
                  displayName = nameController.text;
                  editingName = false;
                });
              },
            ),
          )
        : Tooltip(
            text: "Change display name",
            preferredDirection: AxisDirection.right,
            child: tiamat.IconButton(
              icon: material.Icons.edit,
              onPressed: () {
                setState(() {
                  editingName = true;
                });
              },
            ),
          );
  }
}
