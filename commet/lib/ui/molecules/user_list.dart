import 'package:commet/ui/molecules/user_panel.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';

import '../../client/peer.dart';

class PeerList extends StatefulWidget {
  const PeerList(this.peers, {super.key});

  final List<Peer> peers;

  @override
  State<PeerList> createState() => _PeerListState();
}

class _PeerListState extends State<PeerList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _count = 0;

  @override
  void initState() {
    _count = widget.peers.length;
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
              sizeFactor: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
              child: UserPanel(
                displayName: widget.peers[i].displayName,
                avatar: widget.peers[i].avatar,
                color: widget.peers[i].color,
              )),
        ),
      ),
    );
  }
}
