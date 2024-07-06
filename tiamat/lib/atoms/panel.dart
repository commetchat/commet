import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

@UseCase(name: 'Default', type: Panel)
Widget wbPanel(BuildContext context) {
  return Center(
    child: SizedBox(
      height: 500,
      child: const Center(
          child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Panel(
          mode: TileType.surface,
          header: "Example Panel",
          child: Placeholder(),
        ),
      )),
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel(
      {super.key,
      this.header,
      required this.child,
      this.mode = TileType.surface,
      this.padding = 8,
      this.mainAxisSize = MainAxisSize.max});
  final String? header;
  final Widget child;
  final TileType mode;
  final double padding;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (mode) {
      case TileType.surface:
        color = Theme.of(context).colorScheme.surface;
        break;
      case TileType.surfaceDim:
        color = Theme.of(context).colorScheme.surfaceDim;
        break;
      case TileType.surfaceContainer:
        color = Theme.of(context).colorScheme.surfaceContainer;
        break;
      case TileType.surfaceContainerLow:
        color = Theme.of(context).colorScheme.surfaceContainerLow;
        break;
      case TileType.surfaceContainerLowest:
        color = Theme.of(context).colorScheme.surfaceContainerLowest;
        break;
      case TileType.surfaceContainerHigh:
        color = Theme.of(context).colorScheme.surfaceContainerHigh;
        break;
      case TileType.surfaceContainerHighest:
        color = Theme.of(context).colorScheme.surfaceContainerHighest;
        break;
    }

    var shadows = Theme.of(context).extension<ShadowSettings>();

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color,
          boxShadow: shadows?.shadows),
      child: Column(
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: tiamat.Text.labelLow(
                    header!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
            ),
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
              child: tiamat.Seperator(
                padding: 0,
              ),
            ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: child,
          ),
        ],
      ),
    );
  }
}
