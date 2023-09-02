import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as m;

class GenericRoomEvent extends StatelessWidget {
  const GenericRoomEvent(this.text, this.icon, {super.key});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return m.Material(
      color: m.Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(44, 0, 8, 0),
                  child: Icon(
                    icon,
                    size: 20,
                  ),
                ),
                Flexible(
                  child: Row(
                    children: [
                      Flexible(child: tiamat.Text.labelLow(text)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
