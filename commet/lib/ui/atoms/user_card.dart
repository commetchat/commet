import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../config/app_config.dart';

class UserCard extends StatelessWidget {
  const UserCard(this.name, {this.avatar, super.key, this.detail});
  final ImageProvider? avatar;
  final String name;
  final String? detail;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.all(s(4.0)),
            child: Avatar.medium(image: avatar),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(s(8), 0, s(8), 0),
            child: tiamat.Text.label(
              name,
            ),
          )
        ],
      ),
    );
  }
}
