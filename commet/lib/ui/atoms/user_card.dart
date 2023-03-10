import 'package:commet/ui/atoms/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

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
              child: Text(
                this.name,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.red, fontSize: 17),
              ),
            )
          ],
        ),
      ),
    );
  }
}
