
import 'package:commet/client/client.dart';
import 'package:commet/config/app_config.dart';

import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class UserPanel extends StatefulWidget {
  const UserPanel(this.user, {super.key, this.onClicked});
  final Peer user;
  final Function? onClicked;

  @override
  State<UserPanel> createState() => _UserPanelState();
}

class _UserPanelState extends State<UserPanel> {
  @override
  Widget build(BuildContext context) {
    return Tile.low2(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 3, 0, 3),
        child: Row(
          children: [
            Avatar(
              image: widget.user.avatar!,
              radius: 20,
            ),
            Padding(
              padding: EdgeInsets.all(s(8)),
              child: Container(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tiamat.Text.label(
                      widget.user.displayName,
                    ),
                    tiamat.Text.tiny(widget.user.detail),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
