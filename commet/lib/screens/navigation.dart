import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../ui/atoms/avatar.dart';
import '../widgets/room.dart';

class Navigation extends StatelessWidget {
  const Navigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SpaceView(),
          Container(
            constraints: BoxConstraints(minWidth: 200),
            alignment: Alignment.topLeft,
            color: Colors.black54,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChannelButton(),
                    ChannelButton(),
                    ChannelButton(),
                    ChannelButton(),
                    ChannelButton(),
                    ChannelButton(),
                    ChannelButton(),
                    ChannelButton(),
                    ChannelButton(),
                    ChannelButton(),
                    ChannelButton(),
                    ChannelButton(),
                    ChannelButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChannelButton extends StatelessWidget {
  const ChannelButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(2),
        child: TextButton(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("AKDNJKASD"),
            ),
            onPressed: () {}));
  }
}

class SpaceView extends StatelessWidget {
  const SpaceView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.topLeft,
        color: Colors.black87,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Avatar.medium(
                  image: AssetImage(
                      "asset/images/placeholder/avatars/zombieHead.png")),
              const Avatar.medium(
                  image: AssetImage(
                      "asset/images/placeholder/avatars/robotHead.png")),
              const Avatar.medium(
                  image: AssetImage(
                      "asset/images/placeholder/avatars/maleHead.png")),
              const Avatar.medium(
                  image: AssetImage(
                      "asset/images/placeholder/avatars/femaleHead.png")),
              const Avatar.medium(
                  image: AssetImage(
                      "asset/images/placeholder/avatars/zombieHead.png")),
              const Avatar.medium(
                  image: AssetImage(
                      "asset/images/placeholder/avatars/robotHead.png")),
              const Avatar.medium(
                  image: AssetImage(
                      "asset/images/placeholder/avatars/maleHead.png")),
              const Avatar.medium(
                  image: AssetImage(
                      "asset/images/placeholder/avatars/femaleHead.png")),
              const Avatar.medium(
                  image: AssetImage(
                      "asset/images/placeholder/avatars/zombieHead.png")),
              const Avatar.medium(
                  image: AssetImage(
                      "asset/images/placeholder/avatars/robotHead.png")),
              const Avatar.medium(
                  image: AssetImage(
                      "asset/images/placeholder/avatars/maleHead.png")),
              const Avatar.medium(
                  image: AssetImage(
                      "asset/images/placeholder/avatars/femaleHead.png"))
            ],
          ),
        ));
  }
}
