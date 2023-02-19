import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../client/client.dart';
import '../../config/style/theme_extensions.dart';
import '../atoms/room_button.dart';

class SpaceViewer extends StatefulWidget {
  SpaceViewer(this.space, {super.key, this.onRoomSelected, this.onRoomInsert});
  Space space;
  Stream<int>? onRoomInsert;

  void Function(int)? onRoomSelected;

  @override
  State<SpaceViewer> createState() => _SpaceViewerState();
}

class _SpaceViewerState extends State<SpaceViewer> with TickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _count = 0;
  late StreamSubscription<int>? onInsertListener;
  late StreamSubscription<void>? onUpdateListener;

  @override
  void initState() {
    onUpdateListener = widget.space.onUpdate.stream.listen((event) {
      setState(() {});
    });

    onInsertListener = widget.onRoomInsert?.listen((index) {
      _listKey.currentState?.insertItem(index);
      _count++;
    });

    _count = widget.space.rooms.length;

    super.initState();
  }

  @override
  void dispose() {
    onInsertListener?.cancel();
    onUpdateListener?.cancel();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    print("Setting state");
    super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).extension<ExtraColors>()!.surfaceLow,
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AnimatedList(
                    key: _listKey,
                    initialItemCount: _count,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, i, animation) => ScaleTransition(
                      scale: animation,
                      child: RoomButton(
                        widget.space.rooms[i],
                        onTap: () => {widget.onRoomSelected?.call(i)},
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
