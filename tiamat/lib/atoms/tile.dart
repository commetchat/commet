import 'package:flutter/material.dart';
import 'package:tiamat/atoms/glass_tile.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

@WidgetbookUseCase(name: 'Default', type: Tile)
Widget wbtileSurface(BuildContext context) {
  return const Tile(child: Center(child: tiamat.Text.body("Hello, World!")));
}

@WidgetbookUseCase(name: 'Low 1', type: Tile)
Widget wbtileSurfaceLow1(BuildContext context) {
  return const Tile.low1(child: Center(child: tiamat.Text.body("Hello, World!")));
}

@WidgetbookUseCase(name: 'Low 2', type: Tile)
Widget wbtileSurfaceLow2(BuildContext context) {
  return const Tile.low2(child: Center(child: tiamat.Text.body("Hello, World!")));
}

@WidgetbookUseCase(name: 'Low 3', type: Tile)
Widget wbtileSurfaceLow3(BuildContext context) {
  return const Tile.low3(child: Center(child: tiamat.Text.body("Hello, World!")));
}

@WidgetbookUseCase(name: 'Low 4', type: Tile)
Widget wbtileSurfaceLow4(BuildContext context) {
  return const Tile.low4(child: Center(child: tiamat.Text.body("Hello, World!")));
}

@WidgetbookUseCase(name: 'High', type: Tile)
Widget wbtileSurfaceHigh(BuildContext context) {
  return const Tile.high(child: Center(child: tiamat.Text.body("Hello, World!")));
}

@WidgetbookUseCase(name: 'All', type: Tile)
Widget tileAll(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisSize: MainAxisSize.max,
    children: [
      Expanded(
          child: Tile.high(
        child: Center(
            child: tiamat.Text.body(
          "Hello, World!",
          
        ),),
      )),
      Expanded(
          child: Tile(
              child: Center(
                  child: tiamat.Text.body(
        "Hello, World!",
      )))),
      Expanded(
          child: Tile.low1(
              child: Center(
                  child: tiamat.Text.body(
        "Hello, World!",
      )))),
      Expanded(
          child: Tile.low2(
              child: Center(
                  child: tiamat.Text.body(
        "Hello, World!",
      )))),
      Expanded(
          child: Tile.low3(
              child: Center(
                  child: tiamat.Text.body(
        "Hello, World!",
      )))),
      Expanded(
          child: Tile.low4(
              child: Center(
                  child: tiamat.Text.body(
        "Hello, World!",
      )))),
    ],
  );
}


@WidgetbookUseCase(name: 'All with border', type: Tile)
Widget tileAllBorders(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisSize: MainAxisSize.max,
    children: [
      Expanded(
          child: Tile.high(
        child: Center(
            child: tiamat.Text.body(
          "Hello, World!",
          
        ),),
        borderBottom: true      )),
      Expanded(
          child: Tile(
              child: Center(
                  child: tiamat.Text.body(
        "Hello, World!",
      )),borderBottom: true)),
      Expanded(
          child: Tile.low1(
              child: Center(
                  child: tiamat.Text.body(
        "Hello, World!",
      )),borderBottom: true)),
      Expanded(
          child: Tile.low2(
              child: Center(
                  child: tiamat.Text.body(
        "Hello, World!",
      )),borderBottom: true)),
      Expanded(
          child: Tile.low3(
              child: Center(
                  child: tiamat.Text.body(
        "Hello, World!",
      )),borderBottom: true,)),
      Expanded(
          child: Tile.low4(
              child: Center(
                  child: tiamat.Text.body(
        "Hello, World!",
      )))),
    ],
  );
}


enum TileType { surface, surfaceLow1, surfaceLow2, surfaceLow3, surfaceLow4, surfaceHigh }

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

  const Tile.low1({Key? key, this.child, this.decoration, this.borderBottom = false,
      this.borderTop = false,
      this.borderLeft = false,
      this.borderRight = false})
      : mode = TileType.surfaceLow1,
        glassOpacity = 0.4,
        glassSigma = 5,
        super(key: key);
  const Tile.low2({Key? key, this.child, this.decoration, this.borderBottom = false,
      this.borderTop = false,
      this.borderLeft = false,
      this.borderRight = false})
      : mode = TileType.surfaceLow2,
        glassOpacity = 0.5,
        glassSigma = 7,
        super(key: key);
  const Tile.low3({Key? key, this.child, this.decoration, this.borderBottom = false,
      this.borderTop = false,
      this.borderLeft = false,
      this.borderRight = false})
      : mode = TileType.surfaceLow3,
        glassOpacity = 0.6,
        glassSigma = 8,
        super(key: key);
  const Tile.low4({Key? key, this.child, this.decoration, this.borderBottom = false,
      this.borderTop = false,
      this.borderLeft = false,
      this.borderRight = false})
      : mode = TileType.surfaceLow4,
        glassOpacity = 0.7,
        glassSigma = 10,
        super(key: key);
  const Tile.high({Key? key, this.child, this.decoration, this.borderBottom = false,
      this.borderTop = false,
      this.borderLeft = false,
      this.borderRight = false})
      : mode = TileType.surfaceHigh,
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
      case TileType.surfaceLow1:
        color = Theme.of(context).extension<ExtraColors>()!.surfaceLow1;
        break;
      case TileType.surfaceLow2:
        color = Theme.of(context).extension<ExtraColors>()!.surfaceLow2;
        break;
      case TileType.surfaceLow3:
        color = Theme.of(context).extension<ExtraColors>()!.surfaceLow3;
        break;
      case TileType.surfaceLow4:
        color = Theme.of(context).extension<ExtraColors>()!.surfaceLow4;
        break;
      case TileType.surfaceHigh:
        color = Theme.of(context).extension<ExtraColors>()!.surfaceHigh1;
        break;
    }

    bool frosted = Theme.of(context).extension<ThemeSettings>()!.frosted;
    var border = BorderSide(color: Theme.of(context).extension<ExtraColors>()!.outline);

    if (!frosted) {
      return Container(
        decoration: decoration ?? BoxDecoration(
          color: color,
          border: Border(
            top : borderTop ? border : BorderSide.none,
            bottom:  borderBottom ? border : BorderSide.none,
            left:  borderLeft ? border : BorderSide.none,
            right:  borderRight ? border : BorderSide.none
          )
        ),
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
