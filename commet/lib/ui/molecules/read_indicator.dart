import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';

import '../../client/peer.dart';

class ReadIndicator extends StatefulWidget {
  const ReadIndicator({super.key, this.onMessageRead, this.initialList});
  final Stream<Peer>? onMessageRead;
  final Iterable<Peer>? initialList;
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
        child: ShaderMask(
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
              return buildAvatar(widget.initialList!.elementAt(index));
            },
          ),
        ));
  }

  Widget buildAvatar(
    Peer peer,
  ) {
    return Avatar(
      radius: 10,
      image: peer.avatar,
      placeholderText: peer.displayName,
    );
  }
}
