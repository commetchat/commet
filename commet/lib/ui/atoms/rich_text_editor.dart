import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

// ignore: must_be_immutable
class HighlightedEditableText extends EditableText {
  HighlightedEditableText({
    required super.controller,
    required super.focusNode,
    required super.style,
    required super.cursorColor,
    required super.backgroundCursorColor,
    required this.buildTextSpan,
    super.key,
    super.readOnly = false,
    super.obscuringCharacter = '•',
    super.obscureText = false,
    super.autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    super.enableSuggestions = true,
    StrutStyle? strutStyle,
    super.textAlign = TextAlign.start,
    super.textDirection,
    super.locale,
    super.textScaleFactor,
    super.maxLines = 1,
    super.minLines,
    super.expands = false,
    super.forceLine = true,
    super.textHeightBehavior,
    super.textWidthBasis = TextWidthBasis.parent,
    super.autofocus = false,
    bool? showCursor,
    super.showSelectionHandles = false,
    super.selectionColor,
    super.selectionControls,
    TextInputType? keyboardType,
    super.textInputAction,
    super.textCapitalization = TextCapitalization.none,
    super.onChanged,
    super.onEditingComplete,
    super.onSubmitted,
    super.onAppPrivateCommand,
    super.onSelectionChanged,
    super.onSelectionHandleTapped,
    super.onTapOutside,
    super.mouseCursor,
    super.rendererIgnoresPointer = false,
    super.cursorWidth = 2.0,
    super.cursorHeight,
    super.cursorRadius,
    super.cursorOpacityAnimates = false,
    super.cursorOffset,
    super.paintCursorAboveText = false,
    super.scrollPadding = const EdgeInsets.all(20.0),
    super.keyboardAppearance = Brightness.light,
    super.dragStartBehavior = DragStartBehavior.start,
    bool? enableInteractiveSelection,
    super.scrollController,
    super.scrollPhysics,
    super.autocorrectionTextRectColor,
    super.autofillHints = const <String>[],
    super.autofillClient,
    super.clipBehavior = Clip.hardEdge,
    super.restorationId,
    super.scrollBehavior,
    super.scribbleEnabled = true,
    super.enableIMEPersonalizedLearning = true,
    super.contentInsertionConfiguration,
    super.contextMenuBuilder,
    super.spellCheckConfiguration,
    super.magnifierConfiguration = TextMagnifierConfiguration.disabled,
    super.undoController,
    super.selectionHeightStyle = ui.BoxHeightStyle.tight,
    super.selectionWidthStyle = ui.BoxWidthStyle.tight,
  });

  TextSpan Function(String text, BuildContext context) buildTextSpan;

  @override
  HighlightedEditableTextState createState() =>
      // ignore: no_logic_in_create_state
      HighlightedEditableTextState(buildTextSpan);
}

class HighlightedEditableTextState extends EditableTextState {
  TextSpan Function(String text, BuildContext context) textSpanBuilder;
  HighlightedEditableTextState(this.textSpanBuilder);

  @override
  TextSpan buildTextSpan() {
    return textSpanBuilder(textEditingValue.text, context);
  }
}
