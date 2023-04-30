import 'dart:typed_data';

import 'package:commet/ui/molecules/editable_label.dart';
import 'package:commet/ui/molecules/image_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class ProfileEditView extends StatefulWidget {
  const ProfileEditView(
      {super.key,
      required this.avatar,
      required this.displayName,
      required this.identifier,
      this.pickAvatar,
      this.canEditName = false,
      this.setDisplayName});
  final ImageProvider? avatar;
  final String displayName;
  final String identifier;
  final bool canEditName;
  final Function(Uint8List bytes, String? type)? pickAvatar;
  final Function(String name)? setDisplayName;

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  @override
  void initState() {
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
                if (widget.canEditName)
                  EditableLabel(
                    initialText: widget.displayName,
                    type: TextType.largeTitle,
                    onTextConfirmed: (newText) =>
                        widget.setDisplayName?.call(newText!),
                  ),
                if (!widget.canEditName)
                  tiamat.Text.largeTitle(widget.displayName),
                tiamat.Text.labelLow(widget.identifier),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget avatarEditor() {
    return ImagePicker(
      currentImage: widget.avatar,
      withData: true,
      onImageRead: (bytes, mimeType) =>
          widget.pickAvatar?.call(bytes, mimeType),
    );
  }
}
