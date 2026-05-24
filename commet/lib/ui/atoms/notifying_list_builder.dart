import 'dart:async';

import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/widgets.dart';

class NotifyingListBuilder<T> extends StatefulWidget {
  const NotifyingListBuilder(
      {required this.list, required this.builder, super.key});

  final NotifyingList<T> list;
  final Widget? Function(BuildContext context, T value) builder;

  @override
  State<NotifyingListBuilder<T>> createState() =>
      _NotifyingListBuilderState<T>();
}

class _NotifyingListBuilderState<T> extends State<NotifyingListBuilder<T>> {
  late List<StreamSubscription> subs;

  @override
  void initState() {
    subs = [
      widget.list.onAdd.listen(onAdd),
      widget.list.onItemUpdated.listen(onItemUpdated),
      widget.list.onRemove.listen(onRemove),
      widget.list.onListUpdated.listen(onListUpdated),
    ];
    super.initState();
  }

  @override
  void dispose() {
    for (var sub in subs) sub.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.list.length,
      itemBuilder: (context, index) {
        var item = widget.list[index];

        return widget.builder(context, item);
      },
    );
  }

  void onAdd(int event) {}

  void onItemUpdated(int event) {}

  void onRemove(int event) {}

  void onListUpdated(event) {
    setState(() {});
  }
}
