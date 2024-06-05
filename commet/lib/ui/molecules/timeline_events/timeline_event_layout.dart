import 'package:flutter/widgets.dart';

abstract class TimelineEventViewWidget {
  void update(int newIndex);
}

abstract class SelectableEventViewWidget {
  void select(LayerLink link);

  void deselect();
}
