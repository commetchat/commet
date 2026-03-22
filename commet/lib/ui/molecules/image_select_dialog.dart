import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

enum ImageEditAction {
  cancel,
  remove,
  pick,
}

Future<ImageEditAction?> showImageSelectDialog(
  BuildContext context, {
  required ImageProvider? image,
  String title = "Change Image",
}) {
  return AdaptiveDialog.show<ImageEditAction>(
    context,
    title: title,
    scrollable: false,
    builder: (dialogContext) {
      return ImageSelectDialog(
        image: image,
        onCancel: () => Navigator.of(dialogContext).pop(ImageEditAction.cancel),
        onRemove: () => Navigator.of(dialogContext).pop(ImageEditAction.remove),
        onPick: () => Navigator.of(dialogContext).pop(ImageEditAction.pick),
      );
    },
  );
}

class ImageSelectDialog extends StatelessWidget {
  const ImageSelectDialog({
    super.key,
    required this.image,
    required this.onCancel,
    required this.onRemove,
    required this.onPick,
  });

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
            text: "Cancel",
            onTap: onCancel,
          ),
        ),
        Expanded(
          child: tiamat.Button(
            text: "Remove Image",
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
            text: "Pick Image",
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
            text: "Pick Image",
            onTap: onPick,
          ),
          tiamat.Button(
            text: "Remove Image",
            type: tiamat.ButtonType.danger,
            onTap: () async {
              if (await confirmRemove(context)) {
                onRemove();
              }
            },
          ),
          tiamat.Button.secondary(
            text: "Cancel",
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
                        child: tiamat.Text.labelLow("No image set"),
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
      title: "Remove Image",
      scrollable: false,
      builder: (dialogContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            tiamat.Text.body(
              "Are you sure you want to remove this image?",
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: tiamat.Button.secondary(
                    text: "Cancel",
                    onTap: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                Expanded(
                  child: tiamat.Button(
                    text: "Remove",
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