import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/ui/molecules/editable_label.dart';
import 'package:commet/ui/molecules/image_picker.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:commet/utils/image/lod_image.dart';
import 'package:commet/utils/link_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomAppearanceSettingsView extends StatefulWidget {
  const RoomAppearanceSettingsView(
      {required this.avatar,
      required this.displayName,
      required this.identifier,
      required this.color,
      required this.client,
      this.onImagePicked,
      this.onNameChanged,
      this.topic,
      this.setTopic,
      this.canEditName = false,
      this.canEditTopic = false,
      this.canEditAvatar = false,
      super.key});
  final ImageProvider? avatar;
  final Client client;
  final String displayName;
  final String identifier;
  final String? topic;
  final Color color;
  final Function(Uint8List bytes, String? mimeType)? onImagePicked;
  final Function(String name)? onNameChanged;
  final Future<void> Function(String topic)? setTopic;
  final bool canEditName;
  final bool canEditTopic;
  final bool canEditAvatar;
  @override
  State<RoomAppearanceSettingsView> createState() =>
      _RoomAppearanceSettingsViewState();
}

class _RoomAppearanceSettingsViewState
    extends State<RoomAppearanceSettingsView> {
  String? topic;

  @override
  void initState() {
    final avatar = widget.avatar;
    if (avatar is LODImageProvider) {
      avatar.fetchFullRes();
    }

    topic = widget.topic;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            avatarEditor(),
            Flexible(
              child: Column(
                spacing: 2,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.canEditName)
                    EditableLabel(
                      initialText: widget.displayName,
                      type: tiamat.TextType.largeTitle,
                      onTextConfirmed: (newText) =>
                          widget.onNameChanged?.call(newText!),
                    ),
                  if (!widget.canEditName)
                    tiamat.Text.largeTitle(widget.displayName),
                  tiamat.Text.labelLow(widget.identifier),
                ],
              ),
            ),
          ],
        ),
        if (widget.canEditTopic || widget.topic?.isNotEmpty == true)
          Material(
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            color: ColorScheme.of(context).surfaceContainer,
            child: InkWell(
                onTap: widget.canEditTopic ? editTopic : null,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MarkdownBody(
                      imageBuilder: (uri, title, alt) {
                        if (uri.scheme == "mxc" &&
                            widget.client is MatrixClient) {
                          return SizedBox(
                            height: 50,
                            child: Image(
                                image: MatrixMxcImage(
                                    doFullres: true,
                                    doThumbnail: false,
                                    autoLoadFullRes: true,
                                    uri,
                                    (widget.client as MatrixClient)
                                        .matrixClient)),
                          );
                        }

                        return Container();
                      },
                      styleSheet: MarkdownStyleSheet(
                          a: TextTheme.of(context).bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .extension<ExtraColors>()
                                  ?.linkColor)),
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          LinkUtils.open(Uri.parse(href), context: context);
                        }
                      },
                      data: topic?.isNotEmpty == true ? topic! : "Set a topic"),
                )),
          ),
      ],
    );
  }

  Widget avatarEditor() {
    if (widget.canEditAvatar) {
      return ImagePickerButton(
        currentImage: widget.avatar,
        withData: true,
        cropAspectRatio: 1.0,
        onImageRead: (bytes, mimeType, path) =>
            widget.onImagePicked?.call(bytes, mimeType),
      );
    } else {
      return tiamat.Avatar.large(
        image: widget.avatar,
        placeholderColor: widget.color,
        placeholderText: widget.displayName,
      );
    }
  }

  void editTopic() async {
    var newTopic = await AdaptiveDialog.textPrompt(context,
        multiline: true, title: "Set Topic", initialText: topic);

    if (newTopic != null) {
      ErrorUtils.tryRun(context, () async {
        setState(() {
          topic = newTopic;
        });

        await widget.setTopic?.call(newTopic);
      });
    }
  }
}
