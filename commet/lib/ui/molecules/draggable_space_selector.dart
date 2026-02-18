import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/sidebar/resolved_sidebar_item.dart';
import 'package:commet/client/sidebar/sidebar_manager.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/atoms/dot_indicator.dart';
import 'package:commet/ui/atoms/folder_icon.dart';
import 'package:commet/ui/atoms/space_icon.dart';
import 'package:commet/ui/molecules/space_selector.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/utils/scaled_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class SidebarDragData {
  final String? spaceId;
  final String? folderId;
  final String? fromFolderId;
  final int sourceIndex;

  const SidebarDragData({
    this.spaceId,
    this.folderId,
    this.fromFolderId,
    required this.sourceIndex,
  });

  bool get isDraggingFolder => folderId != null;
  bool get isDraggingSpace => spaceId != null;
}

class DraggableSpaceSelector extends StatefulWidget {
  const DraggableSpaceSelector(
    this.items, {
    super.key,
    required this.width,
    required this.sidebarManager,
    this.onSpaceSelected,
    this.clearSelection,
    this.shouldShowAvatarForSpace,
    this.header,
    this.footer,
  });

  final List<ResolvedSidebarItem> items;
  final double width;
  final SidebarManager sidebarManager;
  final void Function(Space space)? onSpaceSelected;
  final void Function()? clearSelection;
  final bool Function(Space space)? shouldShowAvatarForSpace;
  final Widget? header;
  final Widget? footer;

  @override
  State<DraggableSpaceSelector> createState() =>
      _DraggableSpaceSelectorState();
}

class _DraggableSpaceSelectorState extends State<DraggableSpaceSelector> {
  String get _promptCreateFolder => Intl.message("Create Folder",
      name: "promptCreateFolder", desc: "Title for create folder dialog");

  String get _promptRenameFolder => Intl.message("Rename Folder",
      name: "promptRenameFolder", desc: "Title for rename folder dialog");

  String get _promptFolderName => Intl.message("Folder name",
      name: "promptFolderName", desc: "Hint text for folder name input");

  String get _promptRename => Intl.message("Rename",
      name: "promptRename", desc: "Button label to rename");

  String get _promptCreate => Intl.message("Create",
      name: "promptCreate", desc: "Button label to create");

  String get _promptCancel => Intl.message("Cancel",
      name: "promptCancel", desc: "Button label to cancel");

  String get _promptUngroup => Intl.message("Ungroup",
      name: "promptUngroup", desc: "Context menu option to ungroup a folder");

  String get _promptRemoveFromFolder => Intl.message("Remove from folder",
      name: "promptRemoveFromFolder",
      desc: "Context menu option to remove a space from a folder");

  bool _isDragging = false;
  double _dragDistance = 0;
  Timer? _contextMenuTimer;
  List<tiamat.ContextMenuItem>? _pendingContextItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              physics:
                  BuildConfig.ANDROID ? const BouncingScrollPhysics() : null,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    0, 0, 0, MediaQuery.of(context).scale().padding.bottom),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.header != null)
                      Padding(
                        padding: SpaceSelector.padding,
                        child: widget.header!,
                      ),
                    if (widget.header != null) const tiamat.Seperator(),
                    for (int i = 0; i < widget.items.length; i++)
                      _buildDragItem(i, widget.items[i]),
                    if (_isDragging)
                      _buildInsertionZone(widget.items.length),
                    if (widget.footer != null)
                      Padding(
                        padding: SpaceSelector.padding,
                        child: widget.footer!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDragItem(int index, ResolvedSidebarItem item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isDragging) _buildInsertionZone(index),
        switch (item) {
          ResolvedSpace s => _buildDraggableSpace(index, s),
          ResolvedFolder f => _buildDraggableFolder(index, f),
        },
      ],
    );
  }

  Widget _buildInsertionZone(int insertIndex) {
    return DragTarget<SidebarDragData>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        _handleInsertionDrop(details.data, insertIndex);
      },
      builder: (context, candidates, rejected) {
        final isHovered = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: isHovered ? 8 : 4,
          margin: SpaceSelector.padding,
          decoration: isHovered
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                )
              : null,
        );
      },
    );
  }

  Widget _buildFolderInsertionZone(String folderId, int insertIndex) {
    return DragTarget<SidebarDragData>(
      onWillAcceptWithDetails: (details) => details.data.isDraggingSpace,
      onAcceptWithDetails: (details) {
        if (details.data.fromFolderId == folderId) {
          widget.sidebarManager.reorderWithinFolder(
            folderId,
            details.data.sourceIndex,
            insertIndex,
          );
        } else {
          widget.sidebarManager
              .addSpaceToFolderAt(folderId, details.data.spaceId!, insertIndex);
        }
      },
      builder: (context, candidates, rejected) {
        final isHovered = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: isHovered ? 6 : 2,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: isHovered
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                )
              : null,
        );
      },
    );
  }

  void _handleInsertionDrop(SidebarDragData data, int insertIndex) {
    if (data.isDraggingFolder) {
      widget.sidebarManager.reorder(data.sourceIndex, insertIndex);
    } else if (data.fromFolderId != null) {
      widget.sidebarManager
          .moveSpaceOutOfFolder(data.fromFolderId!, data.spaceId!, insertIndex);
    } else {
      widget.sidebarManager.reorder(data.sourceIndex, insertIndex);
    }
  }

  Widget _buildDraggableSpace(int index, ResolvedSpace item,
      {String? folderId, int? indexInFolder, double? widthOverride}) {
    final dragData = SidebarDragData(
      spaceId: item.space.identifier,
      fromFolderId: folderId,
      sourceIndex: folderId != null ? (indexInFolder ?? index) : index,
    );
    final w = widthOverride ?? widget.width;

    Widget spaceIcon = _buildSpaceIconWidget(item.space, width: w);

    Widget content = folderId == null
        ? DragTarget<SidebarDragData>(
            onWillAcceptWithDetails: (details) =>
                details.data.isDraggingSpace &&
                details.data.spaceId != item.space.identifier,
            onAcceptWithDetails: (details) {
              _showCreateFolderDialog(details.data, item, index);
            },
            builder: (context, candidates, rejected) {
              final isHovered = candidates.isNotEmpty;
              Widget child = spaceIcon;
              if (isHovered) {
                child = Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: child,
                );
              }
              return child;
            },
          )
        : spaceIcon;

    final contextItems = <tiamat.ContextMenuItem>[
      if (folderId != null)
        tiamat.ContextMenuItem(
          text: _promptRemoveFromFolder,
          icon: Icons.folder_off,
          onPressed: () => widget.sidebarManager
              .removeSpaceFromFolder(folderId, item.space.identifier),
        ),
    ];

    return _wrapDraggable(
      dragData,
      contextItems.isNotEmpty
          ? AdaptiveContextMenu(items: contextItems, child: content)
          : content,
      avatar: item.space.avatar,
      placeholderColor: item.space.color,
      placeholderText: item.space.displayName,
    );
  }

  Widget _buildSpaceIconWidget(Space space, {double? width}) {
    final w = width ?? widget.width;
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Padding(
          padding: SpaceSelector.padding,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
            child: SpaceIcon(
              displayName: space.displayName,
              onUpdate: space.onUpdate,
              avatar: space.avatar,
              userAvatar: space.client.self!.avatar,
              spaceId: space.identifier,
              userColor: space.client.self!.defaultColor,
              userDisplayName: space.client.self!.displayName,
              highlightedNotificationCount:
                  space.displayHighlightedNotificationCount,
              notificationCount: space.displayNotificationCount,
              width: w,
              placeholderColor: space.color,
              onTap: () {
                widget.onSpaceSelected?.call(space);
              },
              showUser:
                  widget.shouldShowAvatarForSpace?.call(space) ?? false,
            ),
          ),
        ),
        if (space.displayNotificationCount > 0) _messageOverlay(),
      ],
    );
  }

  Widget _wrapDraggable(
    SidebarDragData data,
    Widget child, {
    ImageProvider? avatar,
    Color? placeholderColor,
    String? placeholderText,
    Widget? customFeedback,
    List<tiamat.ContextMenuItem>? mobileContextItems,
  }) {
    final feedbackWidget = customFeedback ??
        Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.8,
            child: SizedBox(
              width: 56,
              height: 56,
              child: tiamat.Avatar(
                radius: 28,
                image: avatar,
                placeholderColor: placeholderColor,
                placeholderText: placeholderText,
              ),
            ),
          ),
        );

    void onDragStarted() {
      HapticFeedback.mediumImpact();
      _dragDistance = 0;
      _contextMenuTimer?.cancel();

      if (!Layout.desktop &&
          mobileContextItems != null &&
          mobileContextItems.isNotEmpty) {
        _pendingContextItems = mobileContextItems;
        _contextMenuTimer = Timer(const Duration(milliseconds: 1200), () {
          if (_dragDistance < 50 && _pendingContextItems != null) {
            HapticFeedback.mediumImpact();
            _showMobileContextMenu(_pendingContextItems!);
            _pendingContextItems = null;
          }
        });
      }

      setState(() => _isDragging = true);
    }

    void onDragUpdate(DragUpdateDetails details) {
      _dragDistance += details.delta.distance;
      if (_dragDistance >= 50) {
        _contextMenuTimer?.cancel();
        _contextMenuTimer = null;
        _pendingContextItems = null;
      }
    }

    void onDragEnded(DraggableDetails details) {
      final wasDragging = _isDragging;
      setState(() => _isDragging = false);
      _contextMenuTimer?.cancel();
      _contextMenuTimer = null;

      _pendingContextItems = null;

      if (!details.wasAccepted &&
          wasDragging &&
          data.fromFolderId != null &&
          data.spaceId != null) {
        widget.sidebarManager
            .removeSpaceFromFolder(data.fromFolderId!, data.spaceId!);
      }
    }

    if (Layout.desktop) {
      return Draggable<SidebarDragData>(
        data: data,
        feedback: feedbackWidget,
        childWhenDragging: Opacity(opacity: 0.3, child: child),
        onDragStarted: onDragStarted,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnded,
        child: child,
      );
    } else {
      return LongPressDraggable<SidebarDragData>(
        data: data,
        delay: const Duration(milliseconds: 300),
        feedback: feedbackWidget,
        childWhenDragging: Opacity(opacity: 0.3, child: child),
        hapticFeedbackOnStart: true,
        onDragStarted: onDragStarted,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnded,
        child: child,
      );
    }
  }

  void _showMobileContextMenu(List<tiamat.ContextMenuItem> items) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: items
              .map((item) => ListTile(
                    leading: item.icon != null ? Icon(item.icon) : null,
                    title: Text(item.text),
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      item.onPressed?.call();
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDraggableFolder(int index, ResolvedFolder folder) {
    final folderContextItems = [
      tiamat.ContextMenuItem(
        text: _promptRename,
        icon: Icons.edit,
        onPressed: () => _showRenameFolderDialog(folder),
      ),
      tiamat.ContextMenuItem(
        text: _promptUngroup,
        icon: Icons.folder_off,
        onPressed: () =>
            widget.sidebarManager.ungroupFolder(folder.id),
      ),
    ];

    final dragData = SidebarDragData(
      folderId: folder.id,
      sourceIndex: index,
    );

    Widget folderContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DragTarget<SidebarDragData>(
          onWillAcceptWithDetails: (details) =>
              details.data.isDraggingSpace &&
              !folder.spaces
                  .any((s) => s.identifier == details.data.spaceId),
          onAcceptWithDetails: (details) {
            if (details.data.fromFolderId != null) {
              widget.sidebarManager.removeSpaceFromFolder(
                  details.data.fromFolderId!, details.data.spaceId!);
            }
            widget.sidebarManager
                .addSpaceToFolder(folder.id, details.data.spaceId!);
          },
          builder: (context, candidates, rejected) {
            final isHovered = candidates.isNotEmpty;
            Widget icon = Stack(
              alignment: Alignment.centerLeft,
              children: [
                FolderIcon(
                  name: folder.name,
                  spaces: folder.spaces,
                  isExpanded: folder.isExpanded,
                  width: widget.width,
                  onTap: () => widget.sidebarManager
                      .toggleFolder(folder.id),
                ),
                if (_folderHasNotifications(folder)) _messageOverlay(),
              ],
            );

            if (isHovered) {
              icon = Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: icon,
              );
            }
            return icon;
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: folder.isExpanded
              ? _buildExpandedFolderChildren(folder)
              : const SizedBox.shrink(),
        ),
      ],
    );

    Widget wrapped = Layout.desktop
        ? AdaptiveContextMenu(
            items: folderContextItems,
            child: folderContent,
          )
        : folderContent;

    return _wrapDraggable(
      dragData,
      wrapped,
      mobileContextItems: folderContextItems,
      customFeedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(56 / 3.4),
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
            child: Icon(
              Icons.folder,
              size: 28,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedFolderChildren(ResolvedFolder folder) {
    final spaces = folder.spaces;
    final bottomRadius = (widget.width - 14) / 3.4;
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 2),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHigh,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < spaces.length; i++) ...[
            if (_isDragging) _buildFolderInsertionZone(folder.id, i),
            _buildDraggableSpace(
              -1,
              ResolvedSpace(spaces[i]),
              folderId: folder.id,
              indexInFolder: i,
              widthOverride: widget.width - 8,
            ),
          ],
          if (_isDragging)
            _buildFolderInsertionZone(folder.id, spaces.length),
        ],
      ),
    );
  }

  bool _folderHasNotifications(ResolvedFolder folder) {
    return folder.spaces
        .any((s) => s.displayNotificationCount > 0);
  }

  Widget _messageOverlay() {
    return const Positioned(left: -6, child: DotIndicator());
  }

  void _showCreateFolderDialog(
      SidebarDragData dragData, ResolvedSpace targetItem, int targetIndex) {
    showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(_promptCreateFolder),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: _promptFolderName),
            onSubmitted: (value) =>
                Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_promptCancel),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text),
              child: Text(_promptCreate),
            ),
          ],
        );
      },
    ).then((name) {
      if (name != null && name.isNotEmpty) {
        widget.sidebarManager.createFolder(
          name,
          dragData.spaceId!,
          targetItem.space.identifier,
          targetIndex,
        );
      }
    });
  }

  void _showRenameFolderDialog(ResolvedFolder folder) {
    showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController(text: folder.name);
        return AlertDialog(
          title: Text(_promptRenameFolder),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: _promptFolderName),
            onSubmitted: (value) =>
                Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_promptCancel),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text),
              child: Text(_promptRename),
            ),
          ],
        );
      },
    ).then((name) {
      if (name != null && name.isNotEmpty) {
        widget.sidebarManager.renameFolder(folder.id, name);
      }
    });
  }
}
