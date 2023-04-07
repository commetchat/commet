import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/ui/atoms/rich_text/spans/link.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as dom;
import 'package:tiamat/atoms/button.dart';
import 'package:tiamat/config/style/theme_dark.dart';
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

    return TextUtils.manageRtlSpan(text, spans, isHtml: true);
  }

  static List<InlineSpan> _parseChild(dom.Node element, TextStyle currentStyle) {
    TextStyle theme = currentStyle;
    if (element is dom.Text) {
      return TextUtils.formatString(element.data, allowBigEmoji: true, style: theme);
    }

    List<InlineSpan> parsedText = List.empty(growable: true);

    if (element is dom.Element) {
      theme = updateStyle(theme, element.localName!);
      var span = parseSpecial(element, theme);

      if (span != null) {
        return [span];
      }
    }

    for (var child in element.nodes) {
      parsedText.addAll(_parseChild(child, theme));
    }

    return parsedText;
  }

  static InlineSpan? parseSpecial(dom.Element element, TextStyle style) {
    switch (element.localName) {
      case "a":
        return LinkSpan.create((element.nodes.first as dom.Text).data,
            destination: element.attributes.containsKey('href') ? Uri.tryParse(element.attributes['href']!) : null,
            style: style);
      case "pre":
        if (element.children.isEmpty) break;
        if (element.children.first.localName != "code") break;

        var child = element.children.first;
        String? langauge;

        if (child.attributes.containsKey('class')) {
          var className = child.attributes['class']!;
          if (className.startsWith('language-')) {
            langauge = className.replaceAll('language-', '');
          }
        }

        return WidgetSpan(
            child: Codeblock(
          language: langauge,
          text: child.innerHtml,
        ));
    }
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
        return style.copyWith(
            fontFamily: GoogleFonts.robotoMono().fontFamily, backgroundColor: Colors.black.withAlpha(60));
      default:
    }

    return style;
  }
}
