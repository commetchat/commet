import 'package:commet/client/matrix/components/emoticon/matrix_emoticon.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:commet/utils/link_utils.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:matrix/matrix.dart' as matrix;
import 'package:tiamat/config/style/theme_extensions.dart';

class MatrixHtmlParser {
  static final CodeBlockHtmlExtension _codeBlock = CodeBlockHtmlExtension();
  static final CodeHtmlExtension _code = CodeHtmlExtension();
  static final LinkifyHtmlExtension _linkify = LinkifyHtmlExtension();
  static Widget parse(String text, matrix.Client client) {
    var document = html_parser.parse(text);
    bool big = shouldDoBigEmoji(document);

    // Making a new one of these for every message we pass might make a lot of garbage
    var extension = MatrixEmoticonHtmlExtension(client, big);
    var widget = Html(
      data: text,
      extensions: [
        extension,
        _codeBlock,
        _code,
        _linkify,
      ],
      style: {
        "body": Style(
          padding: HtmlPaddings.all(0),
          margin: Margins(
            bottom: Margin.zero(),
            left: Margin.zero(),
            top: Margin.zero(),
            right: Margin.zero(),
          ),
        ),
        "code": Style(backgroundColor: Colors.black.withAlpha(40))
      },
      onLinkTap: (url, attributes, element) {
        LinkUtils.open(Uri.parse(url!));
      },
    );

    return widget;
  }
}

bool shouldDoBigEmoji(dom.Document document) {
  if (document.body == null) return false;

  for (var node in document.body!.nodes) {
    if (node is dom.Text) {
      for (var char in node.text.characters) {
        if (char.trim() == "") continue;

        if (TextUtils.isEmoji(char)) continue;

        return false;
      }
    } else if (node is dom.Element &&
        !node.attributes.containsKey("data-mx-emoticon")) {
      return false;
    }
  }

  return true;
}

class MatrixEmoticonHtmlExtension extends HtmlExtension {
  final matrix.Client client;
  final bool bigEmoji;
  const MatrixEmoticonHtmlExtension(this.client, this.bigEmoji);

  double get emojiSize => bigEmoji ? 48 : 20;

  @override
  InlineSpan build(ExtensionContext context) {
    Uri? uri;

    if (context.node is dom.Text) {
      var spans = List<InlineSpan>.empty(growable: true);

      for (var char in context.node.text!.characters) {
        if (char.trim() == "") continue;
        spans.add(WidgetSpan(
            child: EmojiWidget(
          UnicodeEmoticon(char),
          height: emojiSize,
        )));
      }

      return TextSpan(children: spans);
    }

    if (context.attributes.containsKey("src")) {
      uri = Uri.parse(context.attributes["src"]!);
    }
    if (uri == null) {
      return TextSpan(text: context.attributes["alt"] ?? "");
    }

    return WidgetSpan(
        child: EmojiWidget(
      MatrixEmoticon(uri, client, shortcode: context.attributes["alt"] ?? ""),
      height: emojiSize,
    ));
  }

  @override
  bool matches(ExtensionContext context) {
    // If text contains only emojis and spaces we can handle this too
    if (context.node is dom.Text) {
      for (var char in context.node.text!.characters) {
        if (char.trim() == "") continue;

        if (TextUtils.isEmoji(char)) continue;

        return false;
      }

      return true;
    }

    return context.attributes.containsKey("data-mx-emoticon");
  }

  static const Set<String> tags = {"img"};

  @override
  Set<String> get supportedTags => tags;
}

class CodeBlockHtmlExtension extends HtmlExtension {
  @override
  InlineSpan build(ExtensionContext context) {
    var element = context.element!.children.first;
    var langauge = element.className.replaceAll('language-', '');
    var code = element.text;
    return WidgetSpan(
        child: Codeblock(
      text: code,
      language: langauge,
    ));
  }

  static const Set<String> tags = {"pre"};

  @override
  Set<String> get supportedTags => tags;
}

class CodeHtmlExtension extends HtmlExtension {
  @override
  InlineSpan build(ExtensionContext context) {
    return TextSpan(
        text: context.node.text,
        style: TextStyle(
            fontFamily: "Code",
            color: Theme.of(context.buildContext!)
                .extension<ExtraColors>()!
                .codeHighlight));
  }

  static const Set<String> tags = {"code"};

  @override
  Set<String> get supportedTags => tags;
}

class LinkifyHtmlExtension extends HtmlExtension {
  @override
  InlineSpan build(ExtensionContext context) {
    return TextSpan(children: TextUtils.linkifyString(context.node.text!));
  }

  @override
  bool matches(ExtensionContext context) {
    return context.node is dom.Text &&
        TextUtils.containsUrl(context.node.text!);
  }

  @override
  Set<String> get supportedTags => {};
}
