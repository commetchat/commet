import 'dart:async';

import 'package:collection/collection.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/rng.dart';

class SidebarEntry extends Object {
  String order;
  String id;

  SidebarEntry(this.id, this.order);
}

class SpaceSidebarEntry extends SidebarEntry {
  Space space;

  SpaceSidebarEntry(this.space, {required String order})
      : super(space.localId, order);
}

class SpaceGroupSidebarEntry extends SidebarEntry {
  String groupId;
  List<SpaceSidebarEntry> spaces;

  SpaceGroupSidebarEntry(this.groupId, this.spaces, {required String order})
      : super(groupId, order);
}

class StringOrderGenerator {
  Map<String, String> idToOrder = {};
  StreamController _onChangedController = StreamController.broadcast();
  Stream get onChange => _onChangedController.stream;

  void setIndex(String id, int index) {
    if (idToOrder.containsKey(id) == false) {
      idToOrder[id] = RandomUtils.getRandomString(10);
    }

    var numEntries = idToOrder.length;

    index = index.clamp(0, numEntries - 1);

    Log.i("Setting entry: $id to index: $index");

    List<String> keys = List.empty(growable: true);

    for (int i = 0; i < numEntries; i++) {
      keys.add(RandomUtils.getRandomString(10));
    }

    keys.sort((a, b) => a.compareTo(b));

    var nthKey = keys.removeAt(index);

    var sorted = idToOrder.entries.where((i) => i.key != id).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (int i = 0; i < sorted.length; i++) {
      var key = sorted[i].key;

      idToOrder[key] = keys[i];
    }

    idToOrder[id] = nthKey;

    var resultSorted = idToOrder.values.sorted((a, b) => a.compareTo(b));
    assert(resultSorted[index] == nthKey);

    _onChangedController.add(null);
  }

  String? get(String id) {
    return idToOrder[id];
  }

  void set(String id, String value) {
    idToOrder[id] = value;
    _onChangedController.add(null);
  }

  void remove(String id) {
    idToOrder.remove(id);
    _onChangedController.add(null);
  }

  bool containsKey(String id) {
    return idToOrder.containsKey(id);
  }
}

abstract class SidebarEntriesComponent<T extends Client>
    implements Component<T> {
  static Stream get onOrderChanged => idToOrder.onChange;

  static StringOrderGenerator idToOrder = StringOrderGenerator();

  static Map<String, StringOrderGenerator> folderOrders = {};

  static StringOrderGenerator getFolderOrder(String folderId) {
    if (folderOrders.containsKey(folderId) == false) {
      folderOrders[folderId] = StringOrderGenerator();
    }

    return folderOrders[folderId]!;
  }

  List<SidebarEntry> getEntries();

  String createFolder(Space space);

  addToFolder(Space space, String folderId, int index);

  removeFromFolder(Space space, String folderId);
}
