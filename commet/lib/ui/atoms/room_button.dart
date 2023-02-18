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
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: TextButton(
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(
                        Icons.tag,
                        weight: 3,
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(alignment: Alignment.centerLeft, child: Text(widget.room.displayName)),
                ),
              ],
            ),
            onPressed: () => widget.onTap?.call()),
      ),
    );
  }
}
