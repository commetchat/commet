import 'package:commet/client/client.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/client/space_child.dart';
import 'package:commet/ui/atoms/room_preview.dart';
import 'package:commet/utils/debounce.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class JoinRoomView extends StatefulWidget {
  const JoinRoomView(this.client,
      {required this.asSpace,
      this.onPicked,
      this.initialRoomAddress,
      super.key});
  final Client client;
  final String? initialRoomAddress;
  final bool asSpace;
  final Function(SpaceChild<dynamic>)? onPicked;

  @override
  State<JoinRoomView> createState() => _JoinRoomViewState();
}

class _JoinRoomViewState extends State<JoinRoomView> {
  Debouncer searchDebouncer = Debouncer(delay: Duration(seconds: 2));

  RoomPreview? preview;
  String text = "";
  bool loading = false;
  bool joinLoading = false;

  late TextEditingController controller;

  String get promptConfirmRoomJoin => Intl.message(
        "Join Room!",
        name: "promptConfirmRoomJoin",
        desc: "Label for a button which confirms the joining of a room",
      );

  String get promptRoomAddress => Intl.message(
        "Room Address",
        name: "promptRoomAddress",
        desc: "Short label to prompt for the input of a room address",
      );

  String get placeholderRoomAlias => Intl.message(
        "#awesome-room",
        name: "placeholderRoomAlias",
        desc: "Placeholder / Example for a room alias.",
      );

  @override
  void initState() {
    controller = TextEditingController(text: widget.initialRoomAddress);
    if (widget.initialRoomAddress != null) {
      onTextChanged(widget.initialRoomAddress!);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                  label: Text(promptRoomAddress),
                  hint: tiamat.Text.labelLow(placeholderRoomAlias)),
              onChanged: (value) {
                onTextChanged(value);
              },
            ),
            Flexible(
              child: SizedBox(
                  height: 200,
                  child: loading
                      ? Center(child: CircularProgressIndicator())
                      : preview != null
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: RoomPreviewView(previewData: preview!),
                            )
                          : Container()),
            ),
          ],
        ),
        tiamat.Button(
          text: promptConfirmRoomJoin,
          isLoading: joinLoading,
          onTap: () async {
            setState(() {
              joinLoading = true;
            });

            SpaceChild? result;
            if (preview?.type == RoomType.space) {
              result = SpaceChildSpace(await widget.client.joinSpace(text));
            } else {
              result = SpaceChildRoom(await widget.client.joinRoom(text));
            }

            widget.onPicked?.call(result);
          },
        )
      ],
    );
  }

  void onTextChanged(String value) {
    text = value;

    if (value.isEmpty) {
      setState(() {
        preview = null;
        loading = false;
      });
      searchDebouncer.cancel();
      return;
    }

    setState(() {
      preview = null;
      loading = true;
    });

    searchDebouncer.run(() async {
      var result = await widget.client.getRoomPreview(value);
      setState(() {
        preview = result;
        loading = false;
      });
    });
  }
}
