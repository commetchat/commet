import 'package:commet/config/app_config.dart';
import 'package:commet/ui/atoms/background.dart';
import 'package:commet/ui/atoms/user_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../client/peer.dart';
import '../../config/style/theme_extensions.dart';

class PeerList extends StatefulWidget {
  PeerList(this.peers, {super.key});

  List<Peer> peers;

  @override
  State<PeerList> createState() => _PeerListState();
}

class _PeerListState extends State<PeerList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _count = 0;

  @override
  void initState() {
    _count = widget.peers.length;
    print(_count);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Background.low1(
      context,
      child: Padding(
        padding: EdgeInsets.all(s(12.0)),
        child: AnimatedList(
          key: _listKey,
          physics: BouncingScrollPhysics(),
          initialItemCount: _count,
          itemBuilder: (context, i, animation) => SizeTransition(
              sizeFactor: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
              child: UserCard(widget.peers[i].displayName, avatar: widget.peers[i].avatar)),
        ),
      ),
    );
  }
}
