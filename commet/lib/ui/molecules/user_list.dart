import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';

import '../../client/room.dart';

class PeerList extends StatefulWidget {
  const PeerList(this.room, {super.key});
  final Room room;

  @override
  State<PeerList> createState() => _PeerListState();
}

class _PeerListState extends State<PeerList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _count = 0;

  @override
  void initState() {
    _count = widget.room.members.length;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Tile.low1(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: AnimatedList(
          key: _listKey,
          physics: const BouncingScrollPhysics(),
          initialItemCount: _count,
          itemBuilder: (context, i, animation) => SizeTransition(
              sizeFactor:
                  animation.drive(CurveTween(curve: Curves.easeOutCubic)),
              child: UserPanel(
                displayName: widget.room.members.elementAt(i).displayName,
                avatar: widget.room.members.elementAt(i).avatar,
                color: widget.room.getColorOfUser(
                    widget.room.members.elementAt(i).identifier),
              )),
        ),
      ),
    );
  }
}
