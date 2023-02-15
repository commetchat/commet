import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../client/client.dart';
import '../atoms/room_button.dart';

class SpaceViewer extends StatefulWidget {
  SpaceViewer(this.space, {super.key, this.onRoomSelected});
  Space space;

  void Function(int)? onRoomSelected;

  @override
  State<SpaceViewer> createState() => _SpaceViewerState();
}

class _SpaceViewerState extends State<SpaceViewer>
    with TickerProviderStateMixin {
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _count = 0;
  late List<Room> _rooms;

  @override
  void initState() {
    widget.space.onUpdate.stream.listen((event) {
      setState(() {});
    });
    _rooms = widget.space.rooms.getItems(onChange: (i) {
      _listKey.currentState?.setState(() {});
    }, onInsert: (i) {
      _listKey.currentState
          ?.insertItem(i, duration: Duration(milliseconds: 300));
      _count++;
    }, onRemove: (i) {
      _count--;
      _listKey.currentState?.removeItem(i, (_, __) => const ListTile());
    });

    _count = _rooms.length;

    super.initState();
  }

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    print("Setting state");
    super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.space.displayName,
                  style: Theme.of(context).textTheme.titleLarge),
              Flexible(
                child: AnimatedList(
                  key: _listKey,
                  initialItemCount: _count,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, i, animation) => ScaleTransition(
                    scale: animation,
                    child: RoomButton(
                      _rooms[i],
                      onTap: () => {widget.onRoomSelected?.call(i)},
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
