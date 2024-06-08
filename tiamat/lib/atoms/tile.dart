import 'package:flutter/material.dart';
import 'package:tiamat/atoms/glass_tile.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

@UseCase(name: 'Default', type: Tile)
Widget wbtileSurface(BuildContext context) {
  return const Tile(child: Center(child: tiamat.Text.body("Hello, World!")));
}

@UseCase(name: 'Low 1', type: Tile)
Widget wbtileSurfaceLow1(BuildContext context) {
  return const Tile.low1(
      child: Center(child: tiamat.Text.body("Hello, World!")));
}

@UseCase(name: 'Low 2', type: Tile)
Widget wbtileSurfaceLow2(BuildContext context) {
  return const Tile.low2(
      child: Center(child: tiamat.Text.body("Hello, World!")));
}

@UseCase(name: 'Low 3', type: Tile)
Widget wbtileSurfaceLow3(BuildContext context) {
  return const Tile.low3(
      child: Center(child: tiamat.Text.body("Hello, World!")));
}

@UseCase(name: 'Low 4', type: Tile)
Widget wbtileSurfaceLow4(BuildContext context) {
  return const Tile.low4(
      child: Center(child: tiamat.Text.body("Hello, World!")));
}

@UseCase(name: 'High', type: Tile)
Widget wbtileSurfaceHigh(BuildContext context) {
  return const Tile.high(
      child: Center(child: tiamat.Text.body("Hello, World!")));
}

@UseCase(name: 'All', type: Tile)
Widget tileAll(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisSize: MainAxisSize.max,
    children: [
      Expanded(
          child: Tile(
              child: Center(
                  child: tiamat.Text.body(
        "Surface",
      )))),
      Expanded(
          child: Tile.surfaceContainer(
              child: Center(
                  child: tiamat.Text.body(
        "Surface Container",
      )))),
      Expanded(
          child: Tile.low(
              child: Center(
                  child: tiamat.Text.body(
        "Low",
      )))),
      Expanded(
          child: Tile.lowest(
              child: Center(
                  child: tiamat.Text.body(
        "Lowest",
      )))),
      Expanded(
          child: Tile.high(
              child: Center(
                  child: tiamat.Text.body(
        "High",
      )))),
    ],
  );
}

enum TileType {
  surface,
  surfaceContainer, // surfaceLow1,
  // surfaceLow2,
  surfaceContainerLow, // surfaceLow3,
  surfaceContainerLowest, // surfaceLow4,
  surfaceContainerHigh, // surfaceHigh
  surfaceContainerHighest,
  surfaceDim,
}

class Tile extends StatelessWidget {
  const Tile(
      {Key? key,
      this.child,
      this.mode = TileType.surface,
      this.glassOpacity = 0.3,
      this.glassSigma = 5,
      this.decoration,
      this.borderBottom = false,
      this.borderTop = false,
      this.borderLeft = false,
      this.borderRight = false})
      : super(key: key);
  final TileType mode;
  final Widget? child;
  final double glassOpacity;
  final double glassSigma;
  final Decoration? decoration;
  final bool borderLeft;
  final bool borderRight;
  final bool borderTop;
  final bool borderBottom;

  @Deprecated("Use surfaceContainer")
  const Tile.low1(
      {Key? key,
      this.child,
      this.decoration,
      this.borderBottom = false,
      this.borderTop = false,
      this.borderLeft = false,
      this.borderRight = false})
      : mode = TileType.surfaceContainer,
        glassOpacity = 0.4,
        glassSigma = 5,
        super(key: key);

  const Tile.surfaceContainer(
      {Key? key,
      this.child,
      this.decoration,
      this.borderBottom = false,
      this.borderTop = false,
      this.borderLeft = false,
      this.borderRight = false})
      : mode = TileType.surfaceContainer,
        glassOpacity = 0.4,
        glassSigma = 5,
        super(key: key);

  @Deprecated("Use Low")
  const Tile.low2(
      {Key? key,
      this.child,
      this.decoration,
      this.borderBottom = false,
      this.borderTop = false,
      this.borderLeft = false,
      this.borderRight = false})
      : mode = TileType.surfaceContainerLow,
        glassOpacity = 0.5,
        glassSigma = 7,
        super(key: key);

  const Tile.low(
      {Key? key,
      this.child,
      this.decoration,
      this.borderBottom = false,
      this.borderTop = false,
      this.borderLeft = false,
      this.borderRight = false})
      : mode = TileType.surfaceContainerLow,
        glassOpacity = 0.4,
        glassSigma = 5,
        super(key: key);

  @Deprecated("Use Low")
  const Tile.low3(
      {Key? key,
      this.child,
      this.decoration,
      this.borderBottom = false,
      this.borderTop = false,
      this.borderLeft = false,
      this.borderRight = false})
      : mode = TileType.surfaceContainerLow,
        glassOpacity = 0.6,
        glassSigma = 8,
        super(key: key);

  @Deprecated("Use Lowest")
  const Tile.low4(
      {Key? key,
      this.child,
      this.decoration,
      this.borderBottom = false,
      this.borderTop = false,
      this.borderLeft = false,
      this.borderRight = false})
      : mode = TileType.surfaceContainerLowest,
        glassOpacity = 0.7,
        glassSigma = 10,
        super(key: key);

  const Tile.lowest(
      {Key? key,
      this.child,
      this.decoration,
      this.borderBottom = false,
      this.borderTop = false,
      this.borderLeft = false,
      this.borderRight = false})
      : mode = TileType.surfaceContainerLowest,
        glassOpacity = 0.4,
        glassSigma = 5,
        super(key: key);

  const Tile.high(
      {Key? key,
      this.child,
      this.decoration,
      this.borderBottom = false,
      this.borderTop = false,
      this.borderLeft = false,
      this.borderRight = false})
      : mode = TileType.surfaceContainerHigh,
        glassOpacity = 0.2,
        glassSigma = 5,
        super(key: key);

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

    bool frosted = Theme.of(context).extension<ThemeSettings>()!.frosted;
    var border = BorderSide(color: Theme.of(context).colorScheme.outline);

    if (!frosted) {
      return Container(
        decoration: decoration ??
            BoxDecoration(
                color: color,
                border: (borderTop || borderBottom || borderLeft || borderRight)
                    ? Border(
                        top: borderTop ? border : BorderSide.none,
                        bottom: borderBottom ? border : BorderSide.none,
                        left: borderLeft ? border : BorderSide.none,
                        right: borderRight ? border : BorderSide.none)
                    : null),
        child: child,
      );
    }

    return GlassTile(
      color: color,
      opacity: glassOpacity,
      sigma: glassSigma,
      child: child,
    );
  }
}
