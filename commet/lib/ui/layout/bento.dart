import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BentoLayout extends StatelessWidget {
  const BentoLayout(this.children, {super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var gridSize = sqrt(children.length).ceil();
        var aspect = constraints.maxWidth / constraints.maxHeight;

        gridSize += max((aspect.round() - 2), 0);

        if (aspect < 1) {
          gridSize += (1 / aspect).round() - 1;
        }

        gridSize = gridSize.clamp(1, children.length);

        var across = ({required List<Widget> children}) => Column(
              children: children,
            ) as Widget;
        var down = ({required List<Widget> children}) => Row(
              children: children,
            ) as Widget;

        if (aspect < 1.3) {
          var temp = across;
          across = down;
          down = temp;
        }

        return (across(
          children: [
            for (var i = 0; i < gridSize; i++)
              if ((i * gridSize >= children.length) == false)
                Expanded(
                  child: down(
                    children: [
                      for (var j = 0; j < gridSize; j++)
                        if (j + (i * gridSize) < children.length)
                          Flexible(
                              child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: children[j + (i * gridSize)],
                          ))
                    ],
                  ),
                )
          ],
        ));
      },
    );
  }
}
