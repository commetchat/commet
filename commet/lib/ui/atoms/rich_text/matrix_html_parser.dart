import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as dom;
import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixHtmlParser {
  static Widget parse(String text) {
    var fragment = htmlParser.parseFragment(text);
    List<InlineSpan> spans = List.empty(growable: true);
    print(text);
    print(fragment);
    fragment.nodes.forEach(
      (element) {
        print(element);
        spans.addAll(_parseChild(element, TextStyle()));
      },
    );
    return Text.rich(TextSpan(children: spans));
  }

  static List<InlineSpan> _parseChild(dom.Node element, TextStyle currentStyle) {
    TextStyle theme = currentStyle;
    if (element is dom.Text) {
      return TextUtils.formatString(element.data, allowBigEmoji: true, style: theme);
    }

    if (element is dom.Element) {
      theme = updateStyle(theme, element.localName!);
    }

    List<InlineSpan> parsedText = List.empty(growable: true);

    for (var child in element.nodes) {
      parsedText.addAll(_parseChild(child, theme));
    }

    return parsedText;
  }

  static TextStyle updateStyle(TextStyle style, String type) {
    switch (type) {
      case "h1":
        return style.copyWith(fontSize: 56, fontWeight: FontWeight.w600);
      case "h2":
        return style.copyWith(fontSize: 52, fontWeight: FontWeight.w600);
      case "h3":
        return style.copyWith(fontSize: 48, fontWeight: FontWeight.w600);
      case "h4":
        return style.copyWith(fontSize: 42, fontWeight: FontWeight.w600);
      case "h5":
        return style.copyWith(fontSize: 36, fontWeight: FontWeight.w600);
      case "em":
        return style.copyWith(fontStyle: FontStyle.italic);
      case "strong":
        return style.copyWith(fontWeight: FontWeight.bold);
      case "code":
        return style.copyWith(backgroundColor: Colors.black);
      default:
    }

    return style;
  }
}
