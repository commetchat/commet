import 'package:collection/collection.dart';
import 'package:commet/client/components/sidebar_component/sidebar_entries_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/space.dart';
import 'package:commet/utils/rng.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/v4.dart';

class MatrixSidebarEntriesComponent
    implements SidebarEntriesComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixSidebarEntriesComponent(this.client);

  Map<String, String> spaceIdToOrder = {};

  Map<String, String> spaceToFolder = {};

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
      folders[folder]!.spaces.add(space);
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
  addToFolder(Space space, String folderId) {
    spaceToFolder[space.identifier] = folderId;

    SidebarEntriesComponent.idToOrder.remove(space.localId);
  }

  @override
  removeFromFolder(Space space, String folderId) {
    spaceToFolder.remove(space.identifier);
    getOrder(space);
  }
}
