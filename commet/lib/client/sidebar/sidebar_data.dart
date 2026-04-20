import 'package:commet/client/sidebar/sidebar_model.dart';

class SidebarData {
  static const String accountDataType = 'im.commet.space_sidebar';
  static const int currentVersion = 1;

  final int version;
  final List<SidebarItem> items;

  const SidebarData({this.version = currentVersion, this.items = const []});

  factory SidebarData.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? currentVersion;
    final rawItems = json['items'] as List<dynamic>? ?? [];

    final items = <SidebarItem>[];
    for (final raw in rawItems) {
      if (raw is! Map<String, dynamic>) continue;

      final type = raw['type'] as String?;
      switch (type) {
        case 'space':
          final id = raw['id'] as String?;
          if (id != null) items.add(SidebarSpace(id));
          break;
        case 'folder':
          final id = raw['id'] as String?;
          final name = raw['name'] as String? ?? '';
          final children = (raw['children'] as List<dynamic>?)
                  ?.whereType<String>()
                  .toList() ??
              [];
          if (id != null && children.isNotEmpty) {
            items.add(SidebarFolder(id: id, name: name, children: children));
          }
          break;
      }
    }

    return SidebarData(version: version, items: items);
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'items': items.map((item) {
        return switch (item) {
          SidebarSpace s => {'type': 'space', 'id': s.spaceId},
          SidebarFolder f => {
              'type': 'folder',
              'id': f.id,
              'name': f.name,
              'children': f.children,
            },
        };
      }).toList(),
    };
  }

  static SidebarData empty() => const SidebarData();
}
