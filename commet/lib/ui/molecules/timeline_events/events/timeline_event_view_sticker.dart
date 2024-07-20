import 'package:flutter/material.dart';

class TimelineEventViewSticker extends StatelessWidget {
  const TimelineEventViewSticker(this.image, {super.key});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 200,
        child: Image(
          image: image,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
