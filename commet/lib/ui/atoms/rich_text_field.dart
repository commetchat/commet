import 'dart:convert';

import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/mention.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;
import 'package:tiamat/config/config.dart';

// ignore: implementation_imports
import 'package:matrix/src/utils/markdown.dart' as mx_markdown;

class RichTextEditingController extends TextEditingController {
  RichTextEditingController({required this.room, super.text});
  final Room room;

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    return build(text, context);
  }

  TextSpan build(String text, BuildContext context) {
    var doc = md.Document(
        encodeHtml: false,
        extensionSet: md.ExtensionSet.gitHubFlavored,
        inlineSyntaxes: [
          mx_markdown.PillSyntax(),
          mx_markdown.SpoilerSyntax()
        ]);

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
      List<TextSpan> children, TextStyle style, md.Node node,
      {Widget? overrideWidget}) {
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

      if (overrideWidget != null) {
        // The total number of items that can be in the span (characters + child widgets) MUST
        // equal the amount of characters in the string it is meant to represent, so that the
        // cursor renders in the correct place.
        // This is a hacky way to acheive that
        var widgetChildren = List<InlineSpan>.generate(
            nodeText.length,
            (i) => WidgetSpan(
                child: Container(
                    child: i == 0
                        ? Transform.translate(
                            offset: Offset(0, 2.5), child: overrideWidget)
                        : SizedBox(
                            width: 0,
                            height: 0,
                          ))));

        children.add(TextSpan(
          children: widgetChildren,
          style: originalStyle,
        ));
      } else {
        children.add(TextSpan(
          text: nodeText,
          style: originalStyle,
        ));
      }

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
        case "span":
          if (node.attributes.containsKey("data-mx-spoiler"))
            style =
                style.copyWith(backgroundColor: style.color?.withAlpha(200));
          break;
        case "code":
          var color =
              Theme.of(context).extension<ExtraColors>()?.codeHighlight ??
                  Theme.of(context).colorScheme.primary;
          style = style.copyWith(
              color: color,
              fontFamily: "code",
              fontFeatures: const [FontFeature.disable("calt")]);
          break;
        case "pre":
          style = style.copyWith(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              fontFamily: "code",
              fontFeatures: const [FontFeature.disable("calt")]);
          break;
        case "a":
          style = style.copyWith(color: Theme.of(context).colorScheme.primary);
          var href = node.attributes["href"];
          if (href != null) {
            var result = MatrixClient.parseMatrixLink(Uri.parse(href));
            if (result != null) {
              var mxId = result.$2;

              for (var element in node.children!) {
                if (result.$1 == MatrixLinkType.user) {
                  var user = room.getMember(mxId);
                  if (user != null) {
                    currentIndex = handleNode(
                        context, currentIndex, text, children, style, element,
                        overrideWidget: MentionWidget(
                            displayName: user.displayName,
                            avatar: user.avatar,
                            style: style,
                            placeholderColor: user.defaultColor));
                    return currentIndex;
                  }
                } else if (result.$1 == MatrixLinkType.room) {
                  var taggedRoom = room.client.getRoom(mxId);

                  if (taggedRoom != null) {
                    currentIndex = handleNode(
                        context, currentIndex, text, children, style, element,
                        overrideWidget: MentionWidget(
                            fallbackIcon: preferences.usePlaceholderRoomAvatars
                                ? null
                                : taggedRoom.icon,
                            displayName: taggedRoom.displayName,
                            avatar: taggedRoom.avatar,
                            style: style,
                            placeholderColor: taggedRoom.defaultColor));
                    return currentIndex;
                  }
                }
              }
            }
          }
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
