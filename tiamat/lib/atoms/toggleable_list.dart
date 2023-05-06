import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/atoms/checkbox.dart';
import 'package:tiamat/atoms/text_button.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@WidgetbookUseCase(name: 'Toggleable String', type: ToggleableList)
Widget wbToggleableList(BuildContext context) {
  return Center(
    child: SizedBox(
      height: 300,
      child: ToggleableList(
        itemCount: 30,
        itemBuilder: (context, index) {
          return TextButton("Example Text $index");
        },
      ),
    ),
  );
}

class ToggleableList extends StatefulWidget {
  const ToggleableList(
      {super.key, required this.itemBuilder, required this.itemCount});
  final int itemCount;
  final Widget? Function(BuildContext context, int index) itemBuilder;

  @override
  State<ToggleableList> createState() => ToggleableListState();
}

class ToggleableListState extends State<ToggleableList> {
  late List<bool?> state;
  late Set<int> selectedIndicies;
  @override
  void initState() {
    state = List.filled(widget.itemCount, false);
    selectedIndicies = Set();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: buildItem,
      itemCount: widget.itemCount,
    );
  }

  Widget? buildItem(BuildContext context, int index) {
    var newWidget = widget.itemBuilder(context, index);
    if (newWidget == null) return null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        newWidget,
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 12, 4),
          child: Checkbox(
            value: state[index],
            onChanged: (value) => onStateChange(value, index),
          ),
        )
      ],
    );
  }

  void onStateChange(bool? value, int index) {
    setState(() {
      state[index] = value;
      if (value == true) {
        selectedIndicies.add(index);
      } else {
        selectedIndicies.remove(index);
      }
    });
  }
}
