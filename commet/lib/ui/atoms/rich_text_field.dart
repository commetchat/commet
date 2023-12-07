import 'dart:convert';

import 'package:commet/ui/atoms/rich_text_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;
import 'package:tiamat/config/config.dart';

class RichTextField extends StatefulWidget {
  const RichTextField(
      {required this.controller,
      required this.focus,
      required this.style,
      this.onTap,
      this.hintText,
      this.readOnly = false,
      this.contextMenuBuilder,
      super.key});
  final TextEditingController controller;
  final FocusNode focus;
  final TextStyle style;
  final bool readOnly;
  final String? hintText;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final GestureTapCallback? onTap;
  @override
  State<RichTextField> createState() => _RichTextFieldState();
}

class RichTextFieldSelectionGestureDetectorBuilder
    extends TextSelectionGestureDetectorBuilder {
  RichTextFieldSelectionGestureDetectorBuilder({
    // ignore: library_private_types_in_public_api
    required _RichTextFieldState state,
  })  : _state = state,
        super(delegate: state);

  final _RichTextFieldState _state;

  @override
  void onForcePressStart(ForcePressDetails details) {
    super.onForcePressStart(details);
    if (delegate.selectionEnabled && shouldShowSelectionToolbar) {
      editableText.showToolbar();
    }
  }

  @override
  void onSingleTapUp(TapDragUpDetails details) {
    super.onSingleTapUp(details);
    _state._requestKeyboard();
    _state.widget.onTap?.call();
  }

  @override
  void onSingleLongTapStart(LongPressStartDetails details) {
    super.onSingleLongTapStart(details);
    if (delegate.selectionEnabled) {
      switch (Theme.of(_state.context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          Feedback.forLongPress(_state.context);
      }
    }
  }
}

class _RichTextFieldState extends State<RichTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  TextSelectionControls? selectionControls;
  bool _showSelectionHandles = false;
  bool isEmpty = true;
  EditableTextState? get _editableText => editableTextKey.currentState;

  TextEditingController get _effectiveController => widget.controller;

  late RichTextFieldSelectionGestureDetectorBuilder
      _selectionGestureDetectorBuilder;

  @override
  final GlobalKey<HighlightedEditableTextState> editableTextKey =
      GlobalKey<HighlightedEditableTextState>();

  @override
  void initState() {
    _selectionGestureDetectorBuilder =
        RichTextFieldSelectionGestureDetectorBuilder(state: this);
    super.initState();
  }

  void _requestKeyboard() {
    _editableText?.requestKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    DefaultSelectionStyle selectionStyle = DefaultSelectionStyle.of(context);

    final bool paintCursorAboveText;
    bool? cursorOpacityAnimates;
    Offset? cursorOffset;
    final Color cursorColor;
    final Color selectionColor;
    Color? autocorrectionTextRectColor;
    Radius? cursorRadius;
    VoidCallback? handleDidGainAccessibilityFocus;

    switch (theme.platform) {
      case TargetPlatform.iOS:
        selectionControls = cupertinoTextSelectionHandleControls;
        final CupertinoThemeData cupertinoTheme = CupertinoTheme.of(context);
        paintCursorAboveText = true;
        cursorOpacityAnimates ??= true;
        cursorColor = selectionStyle.cursorColor ?? cupertinoTheme.primaryColor;
        selectionColor = selectionStyle.selectionColor ??
            cupertinoTheme.primaryColor.withOpacity(0.40);
        cursorRadius ??= const Radius.circular(2.0);
        cursorOffset = Offset(
            iOSHorizontalOffset / MediaQuery.devicePixelRatioOf(context), 0);
        autocorrectionTextRectColor = selectionColor;
        break;
      case TargetPlatform.macOS:
        selectionControls = cupertinoDesktopTextSelectionHandleControls;
        final CupertinoThemeData cupertinoTheme = CupertinoTheme.of(context);
        paintCursorAboveText = true;
        cursorOpacityAnimates ??= false;
        cursorColor = selectionStyle.cursorColor ?? cupertinoTheme.primaryColor;
        selectionColor = selectionStyle.selectionColor ??
            cupertinoTheme.primaryColor.withOpacity(0.40);
        cursorRadius ??= const Radius.circular(2.0);
        cursorOffset = Offset(
            iOSHorizontalOffset / MediaQuery.devicePixelRatioOf(context), 0);
        handleDidGainAccessibilityFocus = () {
          // Automatically activate the TextField when it receives accessibility focus.
          if (!widget.focus.hasFocus && widget.focus.canRequestFocus) {
            widget.focus.requestFocus();
          }
        };
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        selectionControls = materialTextSelectionHandleControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates ??= false;
        cursorColor = selectionStyle.cursorColor ?? theme.colorScheme.primary;
        selectionColor = selectionStyle.selectionColor ??
            theme.colorScheme.primary.withOpacity(0.40);
        break;
      case TargetPlatform.linux:
        paintCursorAboveText = false;
        cursorOpacityAnimates ??= false;
        cursorColor = selectionStyle.cursorColor ?? theme.colorScheme.primary;
        selectionColor = selectionStyle.selectionColor ??
            theme.colorScheme.primary.withOpacity(0.40);
        selectionControls = desktopTextSelectionHandleControls;
        break;
      case TargetPlatform.windows:
        selectionControls = desktopTextSelectionHandleControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates ??= false;
        cursorColor = selectionStyle.cursorColor ?? theme.colorScheme.primary;
        selectionColor = selectionStyle.selectionColor ??
            theme.colorScheme.primary.withOpacity(0.40);
        handleDidGainAccessibilityFocus = () {
          // Automatically activate the TextField when it receives accessibility focus.
          if (!widget.focus.hasFocus && widget.focus.canRequestFocus) {
            widget.focus.requestFocus();
          }
        };
        break;
    }

    isEmpty = _effectiveController.text.isEmpty;

    var child = InputDecorator(
      isFocused: widget.focus.hasFocus,
      baseStyle: widget.style,
      isEmpty: isEmpty,
      decoration: const InputDecoration()
          .applyDefaults(theme.inputDecorationTheme)
          .copyWith(hintText: widget.hintText, border: InputBorder.none),
      child: HighlightedEditableText(
          key: editableTextKey,
          controller: widget.controller,
          focusNode: widget.focus,
          style: widget.style,
          cursorColor: cursorColor,
          selectionColor: selectionStyle.selectionColor,
          backgroundCursorColor: CupertinoColors.inactiveGray,
          showSelectionHandles: _showSelectionHandles,
          selectionControls: selectionControls,
          minLines: 1,
          maxLines: null,
          readOnly: widget.readOnly,
          onSelectionChanged: _handleSelectionChanged,
          autocorrectionTextRectColor: autocorrectionTextRectColor,
          paintCursorAboveText: paintCursorAboveText,
          cursorOffset: cursorOffset,
          onChanged: onChanged,
          contextMenuBuilder: widget.contextMenuBuilder,
          buildTextSpan: buildTextSpan),
    );

    return MouseRegion(
      child: TextFieldTapRegion(
        child: IgnorePointer(
          ignoring: widget.readOnly,
          child: AnimatedBuilder(
            animation: _effectiveController, // changes the _currentLength
            builder: (BuildContext context, Widget? child) {
              return Semantics(
                onTap: widget.readOnly
                    ? null
                    : () {
                        if (!_effectiveController.selection.isValid) {
                          _effectiveController.selection =
                              TextSelection.collapsed(
                                  offset: _effectiveController.text.length);
                        }
                        _requestKeyboard();
                      },
                onDidGainAccessibilityFocus: handleDidGainAccessibilityFocus,
                child: child,
              );
            },
            child: _selectionGestureDetectorBuilder.buildGestureDetector(
              behavior: HitTestBehavior.translucent,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause? cause) {
    bool willShowSelectionHandles = _shouldShowSelectionHandles(cause);
    if (willShowSelectionHandles != _showSelectionHandles) {
      setState(() {
        _showSelectionHandles = willShowSelectionHandles;
      });
    }

    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
      case TargetPlatform.android:
        if (cause == SelectionChangedCause.longPress) {
          _editableText?.bringIntoView(selection.extent);
        }
    }

    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.android:
        break;
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        if (cause == SelectionChangedCause.drag) {
          _editableText?.hideToolbar();
        }
    }
  }

  bool _shouldShowSelectionHandles(SelectionChangedCause? cause) {
    // When the text field is activated by something that doesn't trigger the
    // selection overlay, we shouldn't show the handles either.
    if (!_selectionGestureDetectorBuilder.shouldShowSelectionToolbar) {
      return false;
    }

    if (cause == SelectionChangedCause.keyboard) {
      return false;
    }

    if (widget.readOnly && _effectiveController.selection.isCollapsed) {
      return false;
    }

    if (cause == SelectionChangedCause.longPress ||
        cause == SelectionChangedCause.scribble) {
      return true;
    }

    if (_effectiveController.text.isNotEmpty) {
      return true;
    }

    return false;
  }

  @override
  bool get forcePressEnabled => true;

  @override
  bool get selectionEnabled => true;

  void onChanged(String value) {
    setState(() {
      isEmpty = value.isEmpty;
    });
  }

  TextSpan buildTextSpan(String text, BuildContext context) {
    var doc = md.Document(
        encodeHtml: false, extensionSet: md.ExtensionSet.gitHubFlavored);

    var parsed = doc.parseLines(const LineSplitter().convert(text));

    var children = <TextSpan>[];
    var style = Theme.of(context).textTheme.bodyMedium!;

    int currentIndex = 0;
    for (var element in parsed) {
      currentIndex = handleNode(currentIndex, text, children, style, element);
    }

    if (currentIndex <= text.length - 1) {
      children.add(TextSpan(text: text.substring(currentIndex), style: style));
    }

    return TextSpan(children: children);
  }

  int handleNode(int currentIndex, String text, List<TextSpan> children,
      TextStyle style, md.Node node) {
    var originalStyle = style.copyWith();

    if (node is md.Text) {
      var substr = text.substring(currentIndex);
      var nodeText = node.text;
      var index = substr.indexOf(nodeText);

      if (index == -1) {
        return currentIndex;
      }

      if (index != 0) {
        var sub = substr.substring(0, index);
        children.add(TextSpan(
            text: sub, style: Theme.of(context).textTheme.bodyMedium!));
        currentIndex += sub.length;
      }

      children.add(TextSpan(text: nodeText, style: originalStyle));
      currentIndex += nodeText.length;
    }

    if (node is md.Element) {
      switch (node.tag) {
        case "em":
          style = style.copyWith(fontStyle: FontStyle.italic);
          break;
        case "strong":
          style = style.copyWith(fontWeight: FontWeight.bold);
          break;
        case "code":
          style = style.copyWith(
              color: Theme.of(context).extension<ExtraColors>()!.codeHighlight,
              fontFamily: "code");
          break;
        case "pre":
          style = style.copyWith(
              color: Theme.of(context).extension<ExtraColors>()!.highlight,
              fontFamily: "code");
          break;
        case "a":
          style = style.copyWith(color: Theme.of(context).colorScheme.primary);
          break;
        case "del":
          style = style.copyWith(decoration: TextDecoration.lineThrough);
          break;
        case "h1":
          style = style.copyWith(fontSize: 14 * 2, fontWeight: FontWeight.bold);
          break;
        case "h2":
          style =
              style.copyWith(fontSize: 14 * 1.5, fontWeight: FontWeight.bold);
          break;
        case "h3":
          style =
              style.copyWith(fontSize: 14 * 1.17, fontWeight: FontWeight.bold);
          break;
        case "h4":
          style = style.copyWith(fontSize: 14 * 1, fontWeight: FontWeight.bold);
          break;
        case "h5":
          style =
              style.copyWith(fontSize: 14 * 0.83, fontWeight: FontWeight.bold);
          break;
        case "h6":
          style =
              style.copyWith(fontSize: 14 * 0.67, fontWeight: FontWeight.bold);
          break;
      }

      if (node.children != null) {
        for (var element in node.children!) {
          currentIndex =
              handleNode(currentIndex, text, children, style, element);
        }
      }
    }
    return currentIndex;
  }
}
