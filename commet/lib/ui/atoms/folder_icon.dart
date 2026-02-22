import 'package:commet/client/client.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/atoms/notification_badge.dart';
import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class FolderIcon extends StatelessWidget {
  const FolderIcon({
    super.key,
    required this.name,
    required this.spaces,
    required this.isExpanded,
    required this.onTap,
    this.width = 70,
  });

  final String name;
  final List<Space> spaces;
  final bool isExpanded;
  final VoidCallback onTap;
  final double width;

  int get _highlightedNotificationCount =>
      spaces.fold(0, (sum, s) => sum + s.displayHighlightedNotificationCount);

  @override
  Widget build(BuildContext context) {
    final iconSize = width - 14;
    final radius = iconSize / 3.4;
    final expandedWidth = width - 8;

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? expandedWidth : iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        borderRadius: isExpanded
            ? BorderRadius.vertical(top: Radius.circular(radius))
            : BorderRadius.circular(radius),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isExpanded
            ? _buildFolderOpenIcon(context, iconSize)
            : _buildGrid(context, iconSize),
      ),
    );

    Widget content = GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: iconSize + (isExpanded ? 2 : 4),
        child: Padding(
          padding: EdgeInsets.only(top: 2, bottom: isExpanded ? 0 : 2),
          child: Center(child: container),
        ),
      ),
    );

    if (!Layout.mobile) {
      content = JustTheTooltip(
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: tiamat.Text(name),
        ),
        preferredDirection: AxisDirection.right,
        offset: 5,
        tailLength: 5,
        tailBaseWidth: 5,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: content,
      );
    }

    return Stack(children: [
      content,
      if (_highlightedNotificationCount > 0)
        Positioned(
          right: 0,
          top: 0,
          child: SizedBox(
            width: 20,
            height: 20,
            child: NotificationBadge(_highlightedNotificationCount),
          ),
        ),
    ]);
  }

  Widget _buildFolderOpenIcon(BuildContext context, double size) {
    return SizedBox(
      key: const ValueKey('folder_open'),
      width: size,
      height: size,
      child: Icon(
        Icons.folder_open,
        size: size * 0.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildGrid(BuildContext context, double size) {
    final displaySpaces = spaces.take(4).toList();
    final cellSize = (size - 6) / 2;

    return SizedBox(
      key: const ValueKey('grid'),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Wrap(
          spacing: 2,
          runSpacing: 2,
          children: [
            for (var space in displaySpaces)
              SizedBox(
                width: cellSize,
                height: cellSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: space.avatar != null
                      ? Image(
                          image: space.avatar!,
                          fit: BoxFit.cover,
                        )
                      : tiamat.Avatar(
                          radius: cellSize / 2,
                          placeholderColor: space.color,
                          placeholderText: space.displayName,
                        ),
                ),
              ),
            for (var i = displaySpaces.length; i < 4; i++)
              SizedBox(
                width: cellSize,
                height: cellSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
