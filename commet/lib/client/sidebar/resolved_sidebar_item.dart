import 'package:commet/client/client.dart';

sealed class ResolvedSidebarItem {
  const ResolvedSidebarItem();
}

class ResolvedSpace extends ResolvedSidebarItem {
  final Space space;
  const ResolvedSpace(this.space);
}

class ResolvedFolder extends ResolvedSidebarItem {
  final String id;
  final String name;
  final List<Space> spaces;
  final bool isExpanded;

  const ResolvedFolder({
    required this.id,
    required this.name,
    required this.spaces,
    this.isExpanded = false,
  });
}
