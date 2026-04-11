import 'dart:math';

import 'package:commet/client/matrix/matrix_member.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class SpaceCreatorDescription extends StatelessWidget {
  SpaceCreatorDescription({super.key});

  final textChannelNames = [
    "General",
    "Random",
    "help",
    "shipposting",
    "Modding",
    "Support",
    "Chat",
    "Wisdom",
    "Showcase",
    "Community",
    "Suggestions",
    "Announcements",
  ];

  final voiceChannelNames = ["Gaming", "Movie Night"];

  final photoAlbumNames = [
    "Random Photo Dump",
    "Clips",
    "Art",
  ];

  final calendarNames = [
    "Calendar",
    "Work Schedule",
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        tiamat.Text.labelLow(
            "Spaces are a collection of rooms, they can contain text chats, voice chats and more! They are the perfect way to organize your community or group!"),
        SizedBox(
          height: 30,
        ),
        Wrap(
            clipBehavior: Clip.hardEdge,
            alignment: WrapAlignment.spaceEvenly,
            runSpacing: 24,
            spacing: 24,
            children: buildItems(context))
      ],
    );
  }

  List<Widget> buildItems(BuildContext context) {
    var result = [
      for (int i = 0; i < textChannelNames.length; i++)
        buildSpaceChild(context, textChannelNames[i], Icons.tag, i),
      for (int i = 0; i < voiceChannelNames.length; i++)
        buildSpaceChild(context, voiceChannelNames[i], Icons.volume_up, i),
      for (int i = 0; i < photoAlbumNames.length; i++)
        buildSpaceChild(context, photoAlbumNames[i], Icons.photo, i),
      for (int i = 0; i < calendarNames.length; i++)
        buildSpaceChild(context, calendarNames[i], Icons.calendar_month, i),
    ];

    result.shuffle(Random(11));

    return result;
  }

  Widget buildSpaceChild(
      BuildContext context, String name, IconData icon, int seed) {
    var random = Random(seed);
    var color = MatrixMember.hashColor(seed.toString());
    color = tiamat.Text.adjustColor(context, color);
    return Transform.rotate(
      angle: (random.nextDouble() - 0.5) * 0.2,
      child: Material(
          color: ColorScheme.of(context).surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Icon(
                    icon,
                    color: color,
                  ),
                  tiamat.Text(
                    name,
                    color: color,
                    autoAdjustBrightness: false,
                  )
                ],
              ),
            ),
          )),
    );
  }
}
