import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/sidebar/resolved_sidebar_item.dart';
import 'package:commet/client/sidebar/sidebar_data.dart';
import 'package:commet/client/sidebar/sidebar_model.dart';
import 'package:commet/client/sidebar/sidebar_persistence.dart';
import 'package:commet/utils/debounce.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:uuid/uuid.dart';

class SidebarManager {
  final ClientManager clientManager;

  List<SidebarItem> _rawItems = [];
  List<ResolvedSidebarItem> _resolvedItems = [];
  final Set<String> _expandedFolders = {};
  Client? _filterClient;
  final Debouncer _persistDebouncer =
      Debouncer(delay: const Duration(seconds: 2));

  final List<StreamSubscription> _subscriptions = [];

  List<ResolvedSidebarItem> get items => _resolvedItems;

  final StreamController<void> onSidebarChanged =
      StreamController.broadcast();

  SidebarManager(this.clientManager);

  void init() {
    _loadFromAccountData();
    _resolve();

    _subscriptions.addAll([
      clientManager.onSpaceAdded.listen((_) => _resolve()),
      clientManager.onSpaceRemoved.listen((_) => _resolve()),
      clientManager.onSync.stream.listen((_) => _checkAccountDataChanged()),
      clientManager.onClientAdded.stream.listen((_) {
        _loadFromAccountData();
        _resolve();
      }),
      clientManager.onClientRemoved.stream.listen((_) => _resolve()),
      EventBus.setFilterClient.stream.listen((client) {
        _filterClient = client;
        _resolve();
      }),
    ]);
  }

  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _persistDebouncer.cancel();
    onSidebarChanged.close();
  }

  void _loadFromAccountData() {
    SidebarData? best;
    int bestCount = -1;

    for (var client in clientManager.clients) {
      var data = SidebarPersistence.readFromClient(client);
      if (data.items.length > bestCount) {
        best = data;
        bestCount = data.items.length;
      }
    }

    _rawItems = List.from(best?.items ?? []);
  }

  String? _lastAccountDataHash;

  void _checkAccountDataChanged() {
    for (var client in clientManager.clients) {
      var data = SidebarPersistence.readFromClient(client);
      var hash = data.toJson().toString();
      if (_lastAccountDataHash == null) {
        _lastAccountDataHash = hash;
        return;
      }
      if (hash != _lastAccountDataHash) {
        _lastAccountDataHash = hash;
        _rawItems = List.from(data.items);
        _resolve();
        return;
      }
    }
  }

  void _resolve() {
    final topLevelSpaces = clientManager.spaces
        .where((s) => s.isTopLevel)
        .where(
            (s) => _filterClient == null || s.client == _filterClient)
        .toList();

    final spaceMap = <String, Space>{};
    for (var space in topLevelSpaces) {
      spaceMap.putIfAbsent(space.identifier, () => space);
    }

    final resolved = <ResolvedSidebarItem>[];
    final placedIds = <String>{};

    for (var item in _rawItems) {
      switch (item) {
        case SidebarSpace s:
          final space = spaceMap[s.spaceId];
          if (space != null) {
            resolved.add(ResolvedSpace(space));
            placedIds.add(s.spaceId);
          }
          break;
        case SidebarFolder f:
          final folderSpaces = <Space>[];
          for (var childId in f.children) {
            final space = spaceMap[childId];
            if (space != null) folderSpaces.add(space);
            placedIds.add(childId);
          }

          if (!folderSpaces.isEmpty) {
            if (folderSpaces.length == 1) {
              resolved.add(ResolvedSpace(folderSpaces.first));
            } else {
              resolved.add(ResolvedFolder(
                id: f.id,
                name: f.name,
                spaces: folderSpaces,
                isExpanded: _expandedFolders.contains(f.id),
              ));
            }
          }
          break;
      }
    }

    final unplaced = topLevelSpaces
        .where((s) => !placedIds.contains(s.identifier))
        .toList();

    resolved.insertAll(0, unplaced.reversed.map((s) => ResolvedSpace(s)));

    _resolvedItems = resolved;
    onSidebarChanged.add(null);
  }

  void _debouncedPersist() {
    _persistDebouncer.run(_persist);
  }

  Future<void> _persist() async {
    final data = SidebarData(items: _rawItems);
    _lastAccountDataHash = data.toJson().toString();
    await SidebarPersistence.writeToAllClients(clientManager.clients, data);
  }

  void reorder(int oldIndex, int newIndex) {
    final rawOld = _resolvedToRawIndex(oldIndex);
    final rawNew = _resolvedToRawIndex(newIndex);

    if (rawOld == null) {
      final item = _resolvedItems[oldIndex];
      if (item is! ResolvedSpace) return;
      final spaceItem = SidebarSpace(item.space.identifier);

      if (rawNew != null) {
        _rawItems.insert(rawNew, spaceItem);
      } else {
        _rawItems.add(spaceItem);
      }
    } else if (rawNew == null) {
      final item = _rawItems.removeAt(rawOld);
      _rawItems.insert(0, item);
    } else {
      final adjustedNew = rawNew > rawOld ? rawNew - 1 : rawNew;
      final item = _rawItems.removeAt(rawOld);
      _rawItems.insert(adjustedNew, item);
    }

    _resolve();
    _debouncedPersist();
  }

  int? _resolvedToRawIndex(int resolvedIndex) {
    if (resolvedIndex < 0 || resolvedIndex >= _resolvedItems.length) {
      return _rawItems.length;
    }
    final resolved = _resolvedItems[resolvedIndex];
    switch (resolved) {
      case ResolvedSpace s:
        for (int i = 0; i < _rawItems.length; i++) {
          final raw = _rawItems[i];
          if (raw is SidebarSpace && raw.spaceId == s.space.identifier) {
            return i;
          }
        }
        return null;
      case ResolvedFolder f:
        for (int i = 0; i < _rawItems.length; i++) {
          final raw = _rawItems[i];
          if (raw is SidebarFolder && raw.id == f.id) return i;
        }
        return null;
    }
  }

  void createFolder(
      String name, String spaceIdA, String spaceIdB, int insertIndex) {
    final folderId = const Uuid().v4();

    _rawItems.removeWhere((item) =>
        item is SidebarSpace &&
        (item.spaceId == spaceIdA || item.spaceId == spaceIdB));

    _removeSpaceFromAnyFolder(spaceIdA);
    _removeSpaceFromAnyFolder(spaceIdB);

    final folder = SidebarFolder(
      id: folderId,
      name: name,
      children: [spaceIdA, spaceIdB],
    );

    final clampedIndex = insertIndex.clamp(0, _rawItems.length);
    _rawItems.insert(clampedIndex, folder);

    _resolve();
    _debouncedPersist();
  }

  void addSpaceToFolder(String folderId, String spaceId) {
    _rawItems
        .removeWhere((item) => item is SidebarSpace && item.spaceId == spaceId);

    _removeSpaceFromAnyFolder(spaceId, exceptFolderId: folderId);

    for (int i = 0; i < _rawItems.length; i++) {
      final item = _rawItems[i];
      if (item is SidebarFolder && item.id == folderId) {
        if (!item.children.contains(spaceId)) {
          _rawItems[i] =
              item.copyWith(children: [...item.children, spaceId]);
        }
        break;
      }
    }

    _resolve();
    _debouncedPersist();
  }

  void addSpaceToFolderAt(String folderId, String spaceId, int index) {
    _rawItems
        .removeWhere((item) => item is SidebarSpace && item.spaceId == spaceId);

    _removeSpaceFromAnyFolder(spaceId, exceptFolderId: folderId);

    for (int i = 0; i < _rawItems.length; i++) {
      final item = _rawItems[i];
      if (item is SidebarFolder && item.id == folderId) {
        final children = List<String>.from(item.children);
        children.remove(spaceId);
        final clampedIndex = index.clamp(0, children.length);
        children.insert(clampedIndex, spaceId);
        _rawItems[i] = item.copyWith(children: children);
        break;
      }
    }

    _resolve();
    _debouncedPersist();
  }

  void _removeSpaceFromAnyFolder(String spaceId, {String? exceptFolderId}) {
    for (int i = 0; i < _rawItems.length; i++) {
      final item = _rawItems[i];
      if (item is SidebarFolder &&
          item.id != exceptFolderId &&
          item.children.contains(spaceId)) {
        final newChildren =
            item.children.where((c) => c != spaceId).toList();
        if (newChildren.length <= 1) {
          _rawItems.removeAt(i);
          for (var child in newChildren) {
            _rawItems.insert(i, SidebarSpace(child));
          }
        } else {
          _rawItems[i] = item.copyWith(children: newChildren);
        }
        break;
      }
    }
  }

  void removeSpaceFromFolder(String folderId, String spaceId) {
    for (int i = 0; i < _rawItems.length; i++) {
      final item = _rawItems[i];
      if (item is SidebarFolder && item.id == folderId) {
        final newChildren =
            item.children.where((c) => c != spaceId).toList();

        if (newChildren.length <= 1) {
          _rawItems.removeAt(i);
          for (var child in newChildren) {
            _rawItems.insert(i, SidebarSpace(child));
          }
        } else {
          _rawItems[i] = item.copyWith(children: newChildren);
        }

        _rawItems.insert(
            (i + 1).clamp(0, _rawItems.length), SidebarSpace(spaceId));
        break;
      }
    }

    _resolve();
    _debouncedPersist();
  }

  void moveSpaceOutOfFolder(
      String folderId, String spaceId, int insertIndex) {
    for (int i = 0; i < _rawItems.length; i++) {
      final item = _rawItems[i];
      if (item is SidebarFolder && item.id == folderId) {
        final newChildren =
            item.children.where((c) => c != spaceId).toList();

        if (newChildren.length <= 1) {
          _rawItems.removeAt(i);
          for (var child in newChildren) {
            _rawItems.insert(i, SidebarSpace(child));
          }
        } else {
          _rawItems[i] = item.copyWith(children: newChildren);
        }
        break;
      }
    }

    final clampedIndex = insertIndex.clamp(0, _rawItems.length);
    _rawItems.insert(clampedIndex, SidebarSpace(spaceId));

    _resolve();
    _debouncedPersist();
  }

  void renameFolder(String folderId, String newName) {
    for (int i = 0; i < _rawItems.length; i++) {
      final item = _rawItems[i];
      if (item is SidebarFolder && item.id == folderId) {
        _rawItems[i] = item.copyWith(name: newName);
        break;
      }
    }

    _resolve();
    _debouncedPersist();
  }

  void ungroupFolder(String folderId) {
    for (int i = 0; i < _rawItems.length; i++) {
      final item = _rawItems[i];
      if (item is SidebarFolder && item.id == folderId) {
        _rawItems.removeAt(i);
        for (int j = 0; j < item.children.length; j++) {
          _rawItems.insert(i + j, SidebarSpace(item.children[j]));
        }
        break;
      }
    }

    _expandedFolders.remove(folderId);
    _resolve();
    _debouncedPersist();
  }

  void reorderWithinFolder(String folderId, int oldIndex, int newIndex) {
    for (int i = 0; i < _rawItems.length; i++) {
      final item = _rawItems[i];
      if (item is SidebarFolder && item.id == folderId) {
        final children = List<String>.from(item.children);
        if (oldIndex < 0 ||
            oldIndex >= children.length ||
            newIndex < 0 ||
            newIndex >= children.length) return;
        final moved = children.removeAt(oldIndex);
        children.insert(newIndex, moved);
        _rawItems[i] = item.copyWith(children: children);
        break;
      }
    }

    _resolve();
    _debouncedPersist();
  }

  void toggleFolder(String folderId) {
    if (_expandedFolders.contains(folderId)) {
      _expandedFolders.remove(folderId);
    } else {
      _expandedFolders.add(folderId);
    }
    _resolve();
  }
}
