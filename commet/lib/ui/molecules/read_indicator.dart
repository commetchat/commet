import 'dart:async';

import 'package:commet/client/components/read_receipts/read_receipt_component.dart';
import 'package:commet/client/member.dart';
import 'package:commet/utils/common_animation.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:tiamat/tiamat.dart';

import '../../client/room.dart';

class ReadIndicator extends StatefulWidget {
  const ReadIndicator({super.key, required this.component, required this.room});
  final ReadReceiptComponent component;
  final Room room;
  @override
  State<ReadIndicator> createState() => ReadIndicatorState();
}

class ReadIndicatorState extends State<ReadIndicator> {
  late List<String> receipts;

  StreamSubscription? sub;

  @override
  void initState() {
    sub = widget.component.onReadReceiptsUpdated.listen(onUpdated);
    receipts = widget.component.receipts;
    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  void onUpdated(void event) {
    setState(() {
      receipts = widget.component.receipts;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          child: ImplicitlyAnimatedList(
            itemData: receipts,
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
  late Member member;
  @override
  void initState() {
    member = widget.room.getMemberOrFallback(widget.identifier);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Avatar(
      radius: 10,
      image: member.avatar,
      placeholderColor: widget.room.getColorOfUser(widget.identifier),
      placeholderText: member.displayName,
    );
  }
}
