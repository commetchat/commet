import 'dart:convert';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;
import 'package:tiamat/config/config.dart';

class RichTextEditingController extends TextEditingController {
  RichTextEditingController({String? text}) : super(text: text);

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    return build(text, context);
  }

  TextSpan build(String text, BuildContext context) {
    var doc = md.Document(
        encodeHtml: false, extensionSet: md.ExtensionSet.gitHubFlavored);

    List<md.Node>? parsed;
    try {
      parsed = doc.parseLines(const LineSplitter().convert(text));
    } catch (exception) {
      return TextSpan(text: text);
    }

    var children = <TextSpan>[];
    var style = Theme.of(context).textTheme.bodyMedium!;

    int currentIndex = 0;

    for (var element in parsed) {
      currentIndex =
          handleNode(context, currentIndex, text, children, style, element);
    }

    if (currentIndex <= text.length - 1) {
      children.add(TextSpan(text: text.substring(currentIndex), style: style));
    }

    return TextSpan(children: children);
  }

  int handleNode(BuildContext context, int currentIndex, String text,
      List<TextSpan> children, TextStyle style, md.Node node) {
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
              color: Theme.of(context).colorScheme.primary, fontFamily: "code");
          break;
        case "pre":
          style = style.copyWith(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              handleNode(context, currentIndex, text, children, style, element);
        }
      }
    }
    return currentIndex;
  }
}
