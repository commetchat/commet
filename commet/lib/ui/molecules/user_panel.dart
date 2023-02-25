import 'dart:ui';

import 'package:commet/client/client.dart';
import 'package:commet/ui/atoms/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

import '../../config/style/theme_extensions.dart';

class UserPanel extends StatefulWidget {
  const UserPanel(this.user, {super.key});
  final Peer user;

  @override
  State<UserPanel> createState() => _UserPanelState();
}

class _UserPanelState extends State<UserPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
        child: Row(
          children: [
            TextButton(
              onPressed: () => print("Clicked"),
              child: Row(
                children: [
                  Avatar(
                    image: widget.user.avatar!,
                    radius: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.displayName,
                            style: Theme.of(context).textTheme.titleSmall,
                            textAlign: TextAlign.left,
                          ),
                          Text(widget.user.detail, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Placeholder(
              fallbackWidth: 110,
            )
          ],
        ),
      ),
    );
  }
}
