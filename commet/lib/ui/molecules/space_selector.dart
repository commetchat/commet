import 'package:commet/client/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:provider/provider.dart';

import '../atoms/space_icon.dart';

class SpaceSelector extends StatefulWidget {
  SpaceSelector(this.spaces, {super.key, this.width = 100, this.onSelected});

  double width = 100;
  List<Space> spaces;
  @override
  State<SpaceSelector> createState() => _SpaceSelectorState();
  void Function(int index)? onSelected;
}

class _SpaceSelectorState extends State<SpaceSelector> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(7.0),
        child: SizedBox(
          child: ListView.builder(
            itemCount: widget.spaces.length,
            itemBuilder: (context, index) => SpaceIcon(
              widget.spaces[index],
              width: widget.width,
              onTap: () => widget.onSelected?.call(index),
            ),
          ),
        ),
      ),
    );
  }
}
