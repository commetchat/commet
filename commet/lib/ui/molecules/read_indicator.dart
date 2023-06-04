import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';

import '../../client/peer.dart';
import '../../client/room.dart';

class ReadIndicator extends StatefulWidget {
  const ReadIndicator(
      {super.key, required this.room, this.onMessageRead, this.initialList});
  final Stream<Peer>? onMessageRead;
  final Iterable<String>? initialList;
  final Room room;
  @override
  State<ReadIndicator> createState() => ReadIndicatorState();
}

class ReadIndicatorState extends State<ReadIndicator> {
  @override
  Widget build(BuildContext context) {
    if (widget.initialList == null) {
      return const SizedBox();
    }
    return SizedBox(
        height: 20,
        child: widget.initialList == null
            ? null
            : ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.purple,
                      Colors.transparent,
                    ],
                    stops: [
                      0.0,
                      0.3,
                    ],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstOut,
                child: ListView.builder(
                  itemCount: widget.initialList!.length,
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SingleUserReadIndicator(
                      identifier: widget.initialList!.elementAt(index),
                      room: widget.room,
                    );
                  },
                ),
              ));
  }
}

class SingleUserReadIndicator extends StatefulWidget {
  const SingleUserReadIndicator(
      {required this.identifier, required this.room, super.key});
  final String identifier;
  final Room room;
  @override
  State<SingleUserReadIndicator> createState() =>
      _SingleUserReadIndicatorState();
}

class _SingleUserReadIndicatorState extends State<SingleUserReadIndicator> {
  late Peer peer;
  @override
  void initState() {
    peer = widget.room.client.fetchPeer(widget.identifier);
    peer.loading?.then((_) {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Avatar(
      radius: 10,
      image: peer.avatar,
      placeholderText: peer.displayName,
    );
  }
}
