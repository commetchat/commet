import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../config/app_config.dart';

class UserCard extends StatelessWidget {
  UserCard(this.name, {this.avatar, super.key, this.detail});
  ImageProvider? avatar;
  String name;
  String? detail;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: SizedBox(
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.all(s(4.0)),
              child: Avatar.medium(image: avatar),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(s(8), 0, s(8), 0),
              child: tiamat.Text.label(
                this.name,
              ),
            )
          ],
        ),
      ),
    );
  }
}
