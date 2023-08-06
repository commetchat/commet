import 'package:commet/client/matrix/components/emoticon/matrix_emoticon.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/ui/atoms/rich_text/spans/link.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:matrix/matrix.dart' as matrix;

class MatrixHtmlParser {
  static Widget parse(String text, matrix.Client client) {
    var fragment = html_parser.parseFragment(text);
    List<InlineSpan> spans = List.empty(growable: true);
    for (var element in fragment.nodes) {
      if (element is dom.Element && !doParse(element)) continue;

      spans.addAll(_parseChild(element, const TextStyle(), client));
    }

    spans = handleBigEmoji(spans);

    return TextUtils.manageRtlSpan(text, spans, isHtml: true);
  }

  static List<InlineSpan> handleBigEmoji(List<InlineSpan> spans) {
    if (doBigEmoji(spans)) {
      var emojis = spans.where(
          (element) => element is WidgetSpan && element.child is EmojiWidget);

      double size = emojis.length <= 10 ? 48 : 24;
      return emojis.map((e) {
        var widget = (e as WidgetSpan).child as EmojiWidget;
        widget.height = size;
        return e;
      }).toList();
    } else {
      return spans;
    }
  }

  static bool doBigEmoji(List<InlineSpan> spans) {
    return spans.every((span) {
      if (span is TextSpan &&
          (span.text == null || span.text!.trim().isEmpty)) {
        return true;
      }

      if (span is WidgetSpan && span.child is EmojiWidget) return true;

      return false;
    });
  }

  static List<InlineSpan> _parseChild(
      dom.Node element, TextStyle currentStyle, matrix.Client client) {
    TextStyle theme = currentStyle;
    if (element is dom.Text) {
      return TextUtils.formatString(element.data,
          allowBigEmoji: true, style: theme);
    }

    List<InlineSpan> parsedText = List.empty(growable: true);

    if (element is dom.Element) {
      theme = updateStyle(theme, element.localName!);
      var span = parseSpecial(element, theme, client);

      if (span != null) {
        return [span];
      }
    }

    for (var child in element.nodes) {
      if (child is dom.Element && !doParse(child)) continue;

      parsedText.addAll(_parseChild(child, theme, client));
    }

    return parsedText;
  }

  static bool doParse(dom.Element element) {
    switch (element.localName) {
      case "mx-reply":
        return false;
    }
    return true;
  }

  static InlineSpan? parseSpecial(
      dom.Element element, TextStyle style, matrix.Client client) {
    switch (element.localName) {
      case "img":
        if (element.attributes.containsKey("data-mx-emoticon")) {
          String? uri = element.attributes['src'];
          String? shortcode = element.attributes['alt'];

          if (uri != null) {
            return WidgetSpan(
                child: EmojiWidget(MatrixEmoticon(Uri.parse(uri), client,
                    shortcode: shortcode!)));
          }
        }

        break;
      case "a":
        return LinkSpan.create((element.nodes.first as dom.Text).data,
            destination: element.attributes.containsKey('href')
                ? Uri.tryParse(element.attributes['href']!)
                : null,
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
    return null;
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
            fontFamily: GoogleFonts.robotoMono().fontFamily,
            backgroundColor: Colors.black.withAlpha(60));
      default:
    }

    return style;
  }
}
