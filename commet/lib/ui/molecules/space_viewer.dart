import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../client/client.dart';

class SpaceViewer extends StatefulWidget {
  SpaceViewer(this.space, {super.key});
  Space space;

  @override
  State<SpaceViewer> createState() => _SpaceViewerState();
}

class _SpaceViewerState extends State<SpaceViewer> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        child: Container(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(widget.space.displayName,
                style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    ));
  }
}
