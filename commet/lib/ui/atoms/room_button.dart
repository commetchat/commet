import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class RoomButton extends StatefulWidget {
  RoomButton(this.room, {super.key, this.onTap});
  final Room room;
  void Function()? onTap;

  @override
  State<RoomButton> createState() => _RoomButtonState();
}

class _RoomButtonState extends State<RoomButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: TextButton(
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.room.displayName)),
            onPressed: () => widget.onTap?.call()),
      ),
    );
  }
}
