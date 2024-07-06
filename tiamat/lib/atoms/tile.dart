import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tiamat/atoms/foundation.dart';
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
  return Foundation(
    child: Column(
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
    ),
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
  const Tile({
    Key? key,
    this.child,
    this.mode = TileType.surface,
    this.decoration,
    this.caulkClipTopLeft = false,
    this.caulkClipTopRight = false,
    this.caulkClipBottomLeft = false,
    this.caulkClipBottomRight = false,
    this.caulkPadBottom = false,
    this.caulkPadTop = false,
    this.caulkPadLeft = false,
    this.caulkPadRight = false,
    this.caulkBorderBottom = false,
    this.caulkBorderTop = false,
    this.caulkBorderLeft = false,
    this.caulkBorderRight = false,
  }) : super(key: key);
  final TileType mode;
  final Widget? child;
  final Decoration? decoration;
  final bool caulkClipBottomLeft;
  final bool caulkClipBottomRight;
  final bool caulkClipTopRight;
  final bool caulkClipTopLeft;
  final bool caulkPadLeft;
  final bool caulkPadRight;
  final bool caulkPadTop;
  final bool caulkPadBottom;
  final bool caulkBorderLeft;
  final bool caulkBorderRight;
  final bool caulkBorderTop;
  final bool caulkBorderBottom;

  @Deprecated("Use surfaceContainer")
  const Tile.low1({
    Key? key,
    this.child,
    this.decoration,
    this.caulkClipTopLeft = false,
    this.caulkClipTopRight = false,
    this.caulkClipBottomLeft = false,
    this.caulkClipBottomRight = false,
    this.caulkPadBottom = false,
    this.caulkPadTop = false,
    this.caulkPadLeft = false,
    this.caulkPadRight = false,
    this.caulkBorderBottom = false,
    this.caulkBorderTop = false,
    this.caulkBorderLeft = false,
    this.caulkBorderRight = false,
  })  : mode = TileType.surfaceContainer,
        super(key: key);

  const Tile.surfaceContainer({
    Key? key,
    this.child,
    this.decoration,
    this.caulkClipTopLeft = false,
    this.caulkClipTopRight = false,
    this.caulkClipBottomLeft = false,
    this.caulkClipBottomRight = false,
    this.caulkPadBottom = false,
    this.caulkPadTop = false,
    this.caulkPadLeft = false,
    this.caulkPadRight = false,
    this.caulkBorderBottom = false,
    this.caulkBorderTop = false,
    this.caulkBorderLeft = false,
    this.caulkBorderRight = false,
  })  : mode = TileType.surfaceContainer,
        super(key: key);

  @Deprecated("Use Low")
  const Tile.low2({
    Key? key,
    this.child,
    this.decoration,
    this.caulkClipTopLeft = false,
    this.caulkClipTopRight = false,
    this.caulkClipBottomLeft = false,
    this.caulkClipBottomRight = false,
    this.caulkPadBottom = false,
    this.caulkPadTop = false,
    this.caulkPadLeft = false,
    this.caulkPadRight = false,
    this.caulkBorderBottom = false,
    this.caulkBorderTop = false,
    this.caulkBorderLeft = false,
    this.caulkBorderRight = false,
  })  : mode = TileType.surfaceContainerLow,
        super(key: key);

  const Tile.low({
    Key? key,
    this.child,
    this.decoration,
    this.caulkClipTopLeft = false,
    this.caulkClipTopRight = false,
    this.caulkClipBottomLeft = false,
    this.caulkClipBottomRight = false,
    this.caulkPadBottom = false,
    this.caulkPadTop = false,
    this.caulkPadLeft = false,
    this.caulkPadRight = false,
    this.caulkBorderBottom = false,
    this.caulkBorderTop = false,
    this.caulkBorderLeft = false,
    this.caulkBorderRight = false,
  })  : mode = TileType.surfaceContainerLow,
        super(key: key);

  @Deprecated("Use Low")
  const Tile.low3({
    Key? key,
    this.child,
    this.decoration,
    this.caulkClipTopLeft = false,
    this.caulkClipTopRight = false,
    this.caulkClipBottomLeft = false,
    this.caulkClipBottomRight = false,
    this.caulkPadBottom = false,
    this.caulkPadTop = false,
    this.caulkPadLeft = false,
    this.caulkPadRight = false,
    this.caulkBorderBottom = false,
    this.caulkBorderTop = false,
    this.caulkBorderLeft = false,
    this.caulkBorderRight = false,
  })  : mode = TileType.surfaceContainerLow,
        super(key: key);

  @Deprecated("Use Lowest")
  const Tile.low4({
    Key? key,
    this.child,
    this.decoration,
    this.caulkClipTopLeft = false,
    this.caulkClipTopRight = false,
    this.caulkClipBottomLeft = false,
    this.caulkClipBottomRight = false,
    this.caulkPadBottom = false,
    this.caulkPadTop = false,
    this.caulkPadLeft = false,
    this.caulkPadRight = false,
    this.caulkBorderBottom = false,
    this.caulkBorderTop = false,
    this.caulkBorderLeft = false,
    this.caulkBorderRight = false,
  })  : mode = TileType.surfaceContainerLowest,
        super(key: key);

  const Tile.lowest({
    Key? key,
    this.child,
    this.decoration,
    this.caulkClipTopLeft = false,
    this.caulkClipTopRight = false,
    this.caulkClipBottomLeft = false,
    this.caulkClipBottomRight = false,
    this.caulkPadBottom = false,
    this.caulkPadTop = false,
    this.caulkPadLeft = false,
    this.caulkPadRight = false,
    this.caulkBorderBottom = false,
    this.caulkBorderTop = false,
    this.caulkBorderLeft = false,
    this.caulkBorderRight = false,
  })  : mode = TileType.surfaceContainerLowest,
        super(key: key);

  const Tile.high({
    Key? key,
    this.child,
    this.decoration,
    this.caulkClipTopLeft = false,
    this.caulkClipTopRight = false,
    this.caulkClipBottomLeft = false,
    this.caulkClipBottomRight = false,
    this.caulkPadBottom = false,
    this.caulkPadTop = false,
    this.caulkPadLeft = false,
    this.caulkPadRight = false,
    this.caulkBorderBottom = false,
    this.caulkBorderTop = false,
    this.caulkBorderLeft = false,
    this.caulkBorderRight = false,
  })  : mode = TileType.surfaceContainerHigh,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color = switch (mode) {
      TileType.surface => Theme.of(context).colorScheme.surface,
      TileType.surfaceDim => Theme.of(context).colorScheme.surfaceDim,
      TileType.surfaceContainer =>
        Theme.of(context).colorScheme.surfaceContainer,
      TileType.surfaceContainerLow =>
        Theme.of(context).colorScheme.surfaceContainerLow,
      TileType.surfaceContainerLowest =>
        Theme.of(context).colorScheme.surfaceContainerLowest,
      TileType.surfaceContainerHigh =>
        Theme.of(context).colorScheme.surfaceContainerHigh,
      TileType.surfaceContainerHighest =>
        Theme.of(context).colorScheme.surfaceContainerHighest,
    };

    double glassSigma = 0;
    double glassOpacity = 1;

    var settings = Theme.of(context).extension<ThemeSettings>()!;
    var glass = Theme.of(context).extension<GlassSettings>();
    var shadows = Theme.of(context).extension<ShadowSettings>();

    if (glass != null) {
      glassSigma = switch (mode) {
        TileType.surface => glass.surfaceSigma,
        TileType.surfaceContainer => glass.surfaceContainerSigma,
        TileType.surfaceContainerLow => glass.surfaceContainerLowSigma,
        TileType.surfaceContainerLowest => glass.surfaceContainerLowestSigma,
        TileType.surfaceContainerHigh => glass.surfaceContainerHighSigma,
        TileType.surfaceContainerHighest => glass.surfaceContainerHighestSigma,
        TileType.surfaceDim => glass.surfaceDimSigma,
      };
      glassOpacity = switch (mode) {
        TileType.surface => glass.surfaceOpacity,
        TileType.surfaceContainer => glass.surfaceContainerOpacity,
        TileType.surfaceContainerLow => glass.surfaceContainerLowOpacity,
        TileType.surfaceContainerLowest => glass.surfaceContainerLowestOpacity,
        TileType.surfaceContainerHigh => glass.surfaceContainerHighOpacity,
        TileType.surfaceContainerHighest =>
          glass.surfaceContainerHighestOpacity,
        TileType.surfaceDim => glass.surfaceDimOpacity,
      };
    }

    double caulkBorder = settings.caulkBorderRadius;
    double caulkOuterPadding = settings.caulkPadding;

    bool adaptiveBorder = settings.caulkPadding > 0;

    var radius = BorderRadius.only(
        topLeft: caulkClipTopLeft ? Radius.circular(caulkBorder) : Radius.zero,
        topRight:
            caulkClipTopRight ? Radius.circular(caulkBorder) : Radius.zero,
        bottomLeft:
            caulkClipBottomLeft ? Radius.circular(caulkBorder) : Radius.zero,
        bottomRight:
            caulkClipBottomRight ? Radius.circular(caulkBorder) : Radius.zero);

    var border = BorderSide.none;

    bool borderLeft = caulkBorderLeft;
    bool borderRight = caulkBorderRight;
    bool borderTop = caulkBorderTop;
    bool borderBottom = caulkBorderBottom;

    if (settings.caulkBorders) {
      if (adaptiveBorder) {
        if (caulkClipTopRight) {
          borderTop = true;
          borderRight = true;
        }

        if (caulkClipTopLeft) {
          borderTop = true;
          borderLeft = true;
        }

        if (caulkClipBottomLeft) {
          borderLeft = true;
          borderBottom = true;
        }

        if (caulkClipBottomRight) {
          borderBottom = true;
          borderRight = true;
        }
      }

      border = BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: settings.caulkStrokeThickness);
    }

    return Padding(
      padding: EdgeInsets.only(
          left: caulkPadLeft ? caulkOuterPadding : 0,
          right: caulkPadRight ? caulkOuterPadding : 0,
          top: caulkPadTop ? caulkOuterPadding : 0,
          bottom: caulkPadBottom ? caulkOuterPadding : 0),
      child: Container(
          decoration:
              BoxDecoration(borderRadius: radius, boxShadow: shadows?.shadows),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
              filter: glass != null
                  ? ImageFilter.blur(sigmaX: glassSigma, sigmaY: glassSigma)
                  : ImageFilter.matrix(Matrix4.identity().storage),
              child: Container(
                decoration: BoxDecoration(
                  color: glass != null
                      ? color.withAlpha((glassOpacity * 255.0).toInt())
                      : color,
                  borderRadius: radius,
                  border: Border(
                      top: borderTop ? border : BorderSide.none,
                      left: borderLeft ? border : BorderSide.none,
                      right: borderRight ? border : BorderSide.none,
                      bottom: borderBottom ? border : BorderSide.none),
                ),
                child: child,
              ))),
    );
  }
}
