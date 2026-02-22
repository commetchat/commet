sealed class SidebarItem {
  const SidebarItem();
}

class SidebarSpace extends SidebarItem {
  final String spaceId;
  const SidebarSpace(this.spaceId);
}

class SidebarFolder extends SidebarItem {
  final String id;
  final String name;
  final List<String> children;

  const SidebarFolder({
    required this.id,
    required this.name,
    required this.children,
  });

  SidebarFolder copyWith({String? name, List<String>? children}) {
    return SidebarFolder(
      id: id,
      name: name ?? this.name,
      children: children ?? this.children,
    );
  }
}
