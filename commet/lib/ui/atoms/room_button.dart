import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class RoomButton extends StatefulWidget {
  RoomButton(this.displayText, {super.key, this.onTap, this.icon = Icons.tag});
  final String displayText;
  void Function()? onTap;
  IconData icon = Icons.tag;

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
                Padding(
                  padding: EdgeInsets.all(2.0),
                  child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(
                        widget.icon,
                        weight: 3,
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(alignment: Alignment.centerLeft, child: Text(widget.displayText)),
                ),
              ],
            ),
            onPressed: () => widget.onTap?.call()),
      ),
    );
  }
}
