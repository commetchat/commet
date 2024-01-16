import 'package:commet/utils/common_animation.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:tiamat/tiamat.dart';

import '../../client/peer.dart';
import '../../client/room.dart';

class ReadIndicator extends StatefulWidget {
  const ReadIndicator(
      {super.key, required this.room, this.onMessageRead, this.initialList});
  final Stream<Peer>? onMessageRead;
  final List<String>? initialList;
  final Room room;
  @override
  State<ReadIndicator> createState() => ReadIndicatorState();
}

class ReadIndicatorState extends State<ReadIndicator> {
  @override
  Widget build(BuildContext context) {
    if (widget.initialList == null) {
      return const SizedBox(
        height: 20,
      );
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
                child: ImplicitlyAnimatedList(
                  itemData: widget.initialList!,
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  initialAnimation: false,
                  deleteDuration: Duration.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  insertAnimation: (context, child, animation) {
                    return SizeTransition(
                      sizeFactor: CommonAnimations.easeOut(animation),
                      axis: Axis.horizontal,
                      child: child,
                    );
                  },
                  itemBuilder: (context, data) {
                    return SingleUserReadIndicator(
                      key: ValueKey("user_read_indicator_$data"),
                      identifier: data,
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
    peer = widget.room.client.getPeer(widget.identifier);
    peer.loading?.then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Avatar(
      radius: 10,
      image: peer.avatar,
      placeholderColor: widget.room.getColorOfUser(widget.identifier),
      placeholderText: peer.displayName,
    );
  }
}
