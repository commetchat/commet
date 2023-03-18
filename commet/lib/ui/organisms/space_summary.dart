import 'package:commet/client/client.dart';
import 'package:commet/client/preview_data.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/blurred_image_background.dart';
import 'package:commet/ui/atoms/room_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../atoms/room_panel.dart';

class SpaceSummary extends StatefulWidget {
  const SpaceSummary({required this.space, super.key});
  final Space space;
  @override
  State<SpaceSummary> createState() => _SpaceSummaryState();
}

class _SpaceSummaryState extends State<SpaceSummary> {
  List<PreviewData>? _roomPreviews;
  bool loadingPreviews = false;
  int count = 0;

  @override
  void initState() {
    super.initState();
    loadPreviews();
  }

  void loadPreviews() async {
    setState(() {
      loadingPreviews = true;
    });

    var previews = await widget.space.getUnjoinedRooms();
    print(previews);
    setState(() {
      _roomPreviews = previews;
      loadingPreviews = false;
      count = _roomPreviews!.length;
    });
  }

  void joinRoom(String roomId) {
    widget.space.client.joinRoom(roomId);
  }

  @override
  Widget build(BuildContext context) {
    return tiamat.Tile(
      child: Stack(
        children: [
          SizedBox(
              height: 300,
              child: BlurredImageBackground(
                widget.space.avatar!,
                sigma: 15,
                backgroundColor: Theme.of(context).colorScheme.surface,
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(BuildConfig.MOBILE ? 20 : 50, 150, BuildConfig.MOBILE ? 20 : 50, 0),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Avatar.large(
                      image: widget.space.avatar,
                      placeholderText: widget.space.displayName,
                    ),
                  ),
                  tiamat.Text.label("Welcome to"),
                  tiamat.Text.largeTitle(widget.space.displayName),
                  if (widget.space.topic != null) tiamat.Text.label(widget.space.topic!),
                  Container(
                    height: 20,
                  ),
                  spaceVisibility(),
                  tiamat.Seperator(),
                  if (_roomPreviews != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tiamat.Text.labelEmphasised("Unjoined rooms:"),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: count,
                          itemBuilder: (context, index) {
                            var data = _roomPreviews![index];
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Tile.low1(
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: SizedBox(
                                        height: 50,
                                        child: RoomPanel(
                                          avatar: data.avatar,
                                          displayName: data.displayName!,
                                          topic: data.topic,
                                          showJoinButton: true,
                                          onJoinButtonPressed: () {
                                            joinRoom(_roomPreviews![index].roomId);
                                          },
                                        )),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget spaceVisibility() {
    IconData data = widget.space.visibility == RoomVisibility.public ? Icons.public : Icons.lock;
    String text = widget.space.visibility == RoomVisibility.public ? "Public space" : "Private space";
    return Row(
      children: [
        Icon(data),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: tiamat.Text.label(text),
        )
      ],
    );
  }
}
