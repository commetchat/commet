import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as m;

import '../../config/app_config.dart';

class GenericRoomEvent extends StatelessWidget {
  const GenericRoomEvent(this.text, this.icon, {super.key});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return m.Material(
      color: m.Colors.transparent,
      child: Padding(
        padding: EdgeInsets.all(s(2.0)),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.fromLTRB(s(20), s(8), s(20), s(8)),
            child: Row(
              children: [
                const Avatar.medium(image: null, isPadding: true),
                Icon(icon),
                Padding(
                  padding: EdgeInsets.fromLTRB(s(10), 0, 0, 0),
                  child: tiamat.Text.label(text),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
