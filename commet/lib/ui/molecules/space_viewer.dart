import 'dart:async';

import 'package:commet/ui/atoms/space_list.dart';
import 'package:flutter/material.dart';

import '../../client/client.dart';

class SpaceViewer extends StatefulWidget {
  const SpaceViewer(
    this.space, {
    super.key,
    this.onRoomSelected,
    this.onChildAdded,
    this.onChildRemoved,
    this.onChildUpdated,
  });
  final Space space;
  final Stream<void>? onChildAdded;
  final Stream<void>? onChildRemoved;
  final Stream<void>? onChildUpdated;
  final void Function(Room)? onRoomSelected;

  @override
  State<SpaceViewer> createState() => _SpaceViewerState();
}

class _SpaceViewerState extends State<SpaceViewer> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SpaceList(
            widget.space,
            onRoomSelected: widget.onRoomSelected,
            onChildAdded: widget.onChildAdded,
            onChildRemoved: widget.onChildRemoved,
            onChildUpdated: widget.onChildUpdated,
          )),
    );
  }
}
