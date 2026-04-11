import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

enum ImageEditAction {
  cancel,
  remove,
  pick,
}

class ImageSelectDialog extends StatelessWidget {
  static Future<ImageEditAction?> show(
    BuildContext context, {
    required ImageProvider? image,
    String? title,
  }) {
    return AdaptiveDialog.show<ImageEditAction>(
      context,
      title: title ?? changeImageDialogTitle,
      scrollable: false,
      builder: (dialogContext) {
        return ImageSelectDialog(
          image: image,
          onCancel: () =>
              Navigator.of(dialogContext).pop(ImageEditAction.cancel),
          onRemove: () =>
              Navigator.of(dialogContext).pop(ImageEditAction.remove),
          onPick: () => Navigator.of(dialogContext).pop(ImageEditAction.pick),
        );
      },
    );
  }

  const ImageSelectDialog({
    super.key,
    required this.image,
    required this.onCancel,
    required this.onRemove,
    required this.onPick,
  });

  static String get changeImageDialogTitle => Intl.message("Change Image",
      name: "changeImageDialogTitle",
      desc: "Title for the dialog used to change an image");

  String get removeImagePrompt => Intl.message("Remove Image",
      name: "removeImagePrompt", desc: "Button text for removing an image");

  String get pickImagePrompt => Intl.message("Pick Image",
      name: "pickImagePrompt", desc: "Button text for picking an image");

  String get confirmRemovePrompt =>
      Intl.message("Are you sure you want to remove this image?",
          name: "confirmRemovePrompt",
          desc: "Prompt text for confirming image removal");

  String get emptyImagePrompt => Intl.message("No image set",
      name: "emptyImagePrompt",
      desc: "Text shown when there is no image to display");

  final ImageProvider? image;
  final VoidCallback onCancel;
  final VoidCallback onRemove;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    Widget buttons = Row(
      spacing: 8,
      children: [
        Expanded(
          child: tiamat.Button.secondary(
            text: CommonStrings.promptCancel,
            onTap: onCancel,
          ),
        ),
        Expanded(
          child: tiamat.Button(
            text: removeImagePrompt,
            type: tiamat.ButtonType.danger,
            onTap: () async {
              if (await confirmRemove(context)) {
                onRemove();
              }
            },
          ),
        ),
        Expanded(
          child: tiamat.Button(
            text: pickImagePrompt,
            onTap: onPick,
          ),
        ),
      ],
    );

    if (Layout.mobile) {
      buttons = Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tiamat.Button(
            text: pickImagePrompt,
            onTap: onPick,
          ),
          tiamat.Button(
            text: removeImagePrompt,
            type: tiamat.ButtonType.danger,
            onTap: () async {
              if (await confirmRemove(context)) {
                onRemove();
              }
            },
          ),
          tiamat.Button.secondary(
            text: CommonStrings.promptCancel,
            onTap: onCancel,
          ),
        ],
      );
    }

    return SizedBox(
      width: 700,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 700 / 230,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  image: image != null
                      ? DecorationImage(
                          image: image!,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: image == null
                    ? Center(
                        child: tiamat.Text.labelLow(emptyImagePrompt),
                      )
                    : null,
              ),
            ),
          ),
          buttons,
        ],
      ),
    );
  }

  Future<bool> confirmRemove(BuildContext context) async {
    final confirmed = await AdaptiveDialog.show<bool>(
      context,
      title: removeImagePrompt,
      scrollable: false,
      builder: (dialogContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            tiamat.Text.body(
              confirmRemovePrompt,
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: tiamat.Button.secondary(
                    text: CommonStrings.promptCancel,
                    onTap: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                Expanded(
                  child: tiamat.Button(
                    text: CommonStrings.promptRemove,
                    type: tiamat.ButtonType.danger,
                    onTap: () => Navigator.of(dialogContext).pop(true),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }
}
