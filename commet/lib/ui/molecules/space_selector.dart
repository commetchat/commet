import 'package:commet/client/client.dart';
import 'package:commet/config/style/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:provider/provider.dart';

import '../../utils/union.dart';
import '../atoms/space_icon.dart';

class SpaceSelector extends StatefulWidget {
  SpaceSelector(this.spaces, {super.key, this.width = 100, this.onSelected});

  double width = 100;
  Union<Space> spaces;
  @override
  State<SpaceSelector> createState() => _SpaceSelectorState();
  void Function(int index)? onSelected;
}

class _SpaceSelectorState extends State<SpaceSelector> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _count = 0;
  late final List<Space> _spaces;

  @override
  void initState() {
    _spaces = widget.spaces.getItems(onChange: (i) {
      _listKey.currentState?.setState(() {});
    }, onInsert: (i) {
      _listKey.currentState?.insertItem(i);
      _count++;
    }, onRemove: (i) {
      _count--;
      _listKey.currentState?.removeItem(i, (_, __) => const ListTile());
    });

    _count = _spaces.length;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).extension<ExtraColors>()!.surfaceExtraLow,
      child: Padding(
        padding: const EdgeInsets.all(7.0),
        child: SizedBox(
          child: AnimatedList(
            key: _listKey,
            initialItemCount: _count,
            itemBuilder: (context, i, animation) => ScaleTransition(
              scale: animation,
              child: SpaceIcon(_spaces[i], width: widget.width, onTap: () => widget.onSelected?.call(i)),
            ),
          ),
        ),
      ),
    );
  }
}
