import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/sidebar_component/sidebar_entries_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/space.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/debounce.dart';
import 'package:commet/utils/rng.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';
import 'package:uuid/uuid.dart';

class MatrixSidebarEntryData {
  String? folderId;
  String? order;

  MatrixSidebarEntryData({this.folderId, this.order});

  Map<String, dynamic> toJson() {
    return {
      if (folderId != null) "group": folderId,
      if (order != null) "order": order
    };
  }
}

class MatrixSidebarEntriesComponent
    implements SidebarEntriesComponent<MatrixClient>, NeedsPostLoginInit {
  @override
  MatrixClient client;

  MatrixSidebarEntriesComponent(this.client) {}

  @override
  void postLoginInit() {
    try {
      loadOrderFromAccountData();
    } catch (e, s) {
      Log.onError(e, s);
    }
    SidebarEntriesComponent.onOrderChanged.listen(onChanged);
  }

  void loadOrderFromAccountData() {
    var data = client.matrixClient.accountData[key];

    if (data == null) return;

    var content = data.content as Map<String, dynamic>;

    var spaceData = content.tryGetMap<String, dynamic>("spaces");

    if (spaceData != null) {
      for (var entry in spaceData.entries) {
        var id = entry.key;

        var entryData = entry.value as Map<String, dynamic>;

        var order = entryData.tryGet<String>("order");
        var group = entryData.tryGet<String>("group");
        var space = client.getSpace(id);

        if (space == null) {
          Log.e("Could not find space for ordering!");
          return;
        }

        if (group != null) {
          spaceToFolder[id] = group;
          if (order != null) {
            var orderGen = SidebarEntriesComponent.getFolderOrder(group);
            orderGen.set(space.localId, order);
          }
        } else {
          if (order != null) {
            SidebarEntriesComponent.idToOrder.set(space.localId, order);
          }
        }

        print(content);
      }
    } else {
      Log.w("Could not find any ordering data for spaces");
    }

    var groupData = content.tryGetMap<String, dynamic>("groups");
    if (groupData != null) {
      for (var entry in groupData.entries) {
        var id = entry.key;
        var entryData = entry.value as Map<String, dynamic>;
        var order = entryData.tryGet<String>("order");
        if (order != null) {
          SidebarEntriesComponent.idToOrder.set(id, order);
        }
      }
    } else {
      Log.w("Could not find any ordering data for groups");
    }
  }

  Map<String, String> spaceToFolder = {};

  Debouncer serializeDebouncer = Debouncer(delay: Duration(seconds: 10));

  static const key = "chat.commet.sidebar_ordering";

  void onChanged(event) {
    serializeDebouncer.run(serialize);
  }

  void serialize() {
    var spaces = client.spaces.where((i) => i.isTopLevel);

    Map<String, MatrixSidebarEntryData> data = {};

    Set<String> knownGroups = {};

    for (var space in spaces) {
      String? order = getOrder(space);
      var folder = spaceToFolder[space.identifier];

      if (folder != null) {
        knownGroups.add(folder);
        var orderGen = SidebarEntriesComponent.getFolderOrder(folder);
        order = orderGen.get(space.localId);
      }

      data[space.identifier] =
          MatrixSidebarEntryData(order: order, folderId: folder);
    }

    var spaceData = Map<String, dynamic>.new();

    for (var entry in data.entries) {
      spaceData[entry.key] = entry.value.toJson();
    }

    var groupData = Map<String, Map<String, dynamic>>.new();

    for (var key in knownGroups) {
      var order = SidebarEntriesComponent.idToOrder.get(key);
      if (order != null) {
        groupData[key] = {"order": order};
      }
    }

    var result = {
      "spaces": spaceData,
      if (groupData.isNotEmpty) "groups": groupData,
    };

    client.matrixClient
        .setAccountData(client.matrixClient.userID!, key, result);

    Log.i("Order data: ${result}");
  }

  @override
  List<SidebarEntry> getEntries() {
    var spaces = client.spaces
        .where((i) =>
            i.isTopLevel && spaceToFolder.containsKey(i.identifier) == false)
        .map((i) => SpaceSidebarEntry(i, order: getOrder(i)))
        .toList();

    var spacesInFolders = client.spaces
        .where((i) => spaceToFolder.containsKey(i.identifier) && i.isTopLevel);

    Map<String, SpaceGroupSidebarEntry> folders = {};

    for (var value in spaceToFolder.values) {
      folders[value] = SpaceGroupSidebarEntry(value, List.empty(growable: true),
          order: getGroupOrder(value));
    }

    for (var space in spacesInFolders) {
      var folder = spaceToFolder[space.identifier]!;
      var order = SidebarEntriesComponent.getFolderOrder(folder);

      if (order.containsKey(space.localId) == false) {
        order.set(space.localId, RandomUtils.getRandomString(10));
      }

      folders[folder]!
          .spaces
          .add(SpaceSidebarEntry(space, order: order.get(space.localId)!));
    }

    return [...spaces, ...folders.values];
  }

  String getOrder(Space space) {
    if (SidebarEntriesComponent.idToOrder.containsKey(space.localId) == false) {
      var defaultOrder =
          "__" + space.client.identifier + "_" + space.identifier;
      SidebarEntriesComponent.idToOrder.set(space.localId, defaultOrder);
    }

    return SidebarEntriesComponent.idToOrder.get(space.localId)!;
  }

  String getGroupOrder(String key) {
    if (SidebarEntriesComponent.idToOrder.containsKey(key) == false) {
      var defaultOrder = "__" + key;
      SidebarEntriesComponent.idToOrder.set(key, defaultOrder);
    }

    return SidebarEntriesComponent.idToOrder.get(key)!;
  }

  String createFolder(Space space) {
    var folderId = Uuid().v4();

    spaceToFolder[space.identifier] = folderId;

    var order = SidebarEntriesComponent.idToOrder.get(space.localId)!;
    SidebarEntriesComponent.idToOrder.set(folderId, order);
    SidebarEntriesComponent.idToOrder.remove(space.localId);

    return folderId;
  }

  @override
  addToFolder(Space space, String folderId, int index) {
    spaceToFolder[space.identifier] = folderId;

    SidebarEntriesComponent.idToOrder.remove(space.localId);
    var order = SidebarEntriesComponent.getFolderOrder(folderId);

    order.setIndex(space.localId, index);
  }

  @override
  removeFromFolder(Space space, String folderId) {
    spaceToFolder.remove(space.identifier);
    getOrder(space);
  }
}
