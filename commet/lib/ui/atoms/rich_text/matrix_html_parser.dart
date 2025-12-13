import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/matrix/components/emoticon/matrix_emoticon.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_peer.dart';
import 'package:commet/client/room.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';
import 'package:commet/ui/atoms/mention.dart';
import 'package:commet/ui/atoms/rich_text/spans/link.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:commet/utils/link_utils.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:matrix/matrix.dart' as matrix;
import 'package:tiamat/config/style/theme_extensions.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixHtmlParser {
  static Widget parse(String text, matrix.Client client, Room room) {
    return MatrixHtmlState(
      text,
      client,
      room,
      key: GlobalKey(),
    );
  }
}

class MatrixHtmlState extends StatefulWidget {
  const MatrixHtmlState(this.text, this.client, this.room, {super.key});
  final String text;
  final matrix.Client client;
  final Room room;

  @override
  State<MatrixHtmlState> createState() => _MatrixHtmlStateState();
}

class _MatrixHtmlStateState extends State<MatrixHtmlState> {
  bool hideSpoiler = true;

  static final CodeBlockHtmlExtension _codeBlock = CodeBlockHtmlExtension();
  static final CodeHtmlExtension _code = CodeHtmlExtension();
  static final LineBreakHtmlExtension _lineBreak = LineBreakHtmlExtension();

  static const Set<String> allowedHtmlTags = {
    'body',
    'html',
    'del',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'blockquote',
    'p',
    'a',
    'ul',
    'ol',
    'sup',
    'sub',
    'li',
    'b',
    'i',
    'u',
    'strong',
    'em',
    'strike',
    'code',
    'hr',
    'br',
    'div',
    'table',
    'thead',
    'tbody',
    'tr',
    'th',
    'td',
    'caption',
    'pre',
    'span',
    'img',
    'details',
    'summary',
  };

  void onTap() {
    setState(() {
      hideSpoiler = !hideSpoiler;
    });
  }

  @override
  Widget build(BuildContext context) {
    final SpoilerHtmlExtension spoiler =
        SpoilerHtmlExtension(hideSpoiler, onTap);

    var document = html_parser.parse(widget.text);
    bool big = shouldDoBigEmoji(document);

    // Making a new one of these for every message we pass might make a lot of garbage
    var extension =
        MatrixEmoticonHtmlExtension(widget.client, widget.room, big);
    var imageExtension = MatrixImageExtension(widget.client, widget.room);
    var linkify = LinkifyHtmlExtension(widget.room);
    var result = Html(
      data: widget.text,
      extensions: [
        extension,
        spoiler,
        _codeBlock,
        _code,
        linkify,
        _lineBreak,
        imageExtension
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
          whiteSpace: WhiteSpace.pre, // handled whitespace for #237
        ),
        "code": Style(backgroundColor: Colors.black.withAlpha(40)),
        "blockquote": Style(
          border: Border(
              left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          )),
          padding: HtmlPaddings(
            left: HtmlPadding(4),
          ),
          margin: Margins(
            bottom: Margin(8),
            left: Margin(8),
            top: Margin(8),
            right: Margin.zero(),
          ),
          whiteSpace: WhiteSpace.pre,
        ),
        "p": Style(
          border: Border.all(),
          margin: Margins.all(0),
          padding: HtmlPaddings.all(0),
        )
      },
      onLinkTap: (url, attributes, element) {
        LinkUtils.open(Uri.parse(url!));
      },
      onlyRenderTheseTags: allowedHtmlTags,
    );

    return result;
  }

  void onSpoilerTapped() {
    setState(() {
      hideSpoiler = !hideSpoiler;
    });
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
  final Room room;
  final bool bigEmoji;
  const MatrixEmoticonHtmlExtension(this.client, this.room, this.bigEmoji);

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

    if (room.shouldPreviewMedia == false) {
      return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Tooltip(
              padding: const EdgeInsets.all(0),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              richMessage: WidgetSpan(
                  child: EmojiWidget(
                MatrixEmoticon(uri, client,
                    shortcode: context.attributes["alt"] ?? "",
                    packUsage: EmoticonUsage.all,
                    usage: EmoticonUsage.emoji),
                height: 48,
              )),
              child: tiamat.Text.labelLow(context.attributes["alt"] ?? "")));
    }

    return WidgetSpan(
        child: Tooltip(
      message: context.attributes["alt"] ?? "",
      child: EmojiWidget(
        MatrixEmoticon(uri, client,
            shortcode: context.attributes["alt"] ?? "",
            packUsage: EmoticonUsage.all,
            usage: EmoticonUsage.emoji),
        height: emojiSize,
      ),
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
    var element = context.element!.children.firstOrNull;
    element ??= context.element;

    var langauge = element?.className.replaceAll('language-', '');
    var code = element!.text;
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

class LineBreakHtmlExtension extends HtmlExtension {
  @override
  InlineSpan build(ExtensionContext context) {
    var result =
        context.parser.buildFromExtension(context, extensionsToIgnore: {this});

    if (context.node is! dom.Element) {
      return result;
    }

    return TextSpan(children: [
      if (context.element?.previousElementSibling != null)
        const TextSpan(text: "\n"),
      result,
      if (context.element?.nextElementSibling != null)
        const TextSpan(text: "\n"),
    ]);
  }

  static const Set<String> tags = {"p"};

  @override
  Set<String> get supportedTags => tags;
}

class CodeHtmlExtension extends HtmlExtension {
  @override
  InlineSpan build(ExtensionContext context) {
    var color = Theme.of(context.buildContext!)
            .extension<ExtraColors>()
            ?.codeHighlight ??
        Theme.of(context.buildContext!).primaryColor;

    return TextSpan(
        text: context.node.text,
        style: TextStyle(
            fontFamily: "Code",
            color: color,
            fontFeatures: const [FontFeature.disable("calt")]));
  }

  static const Set<String> tags = {"code"};

  @override
  Set<String> get supportedTags => tags;
}

class LinkifyHtmlExtension extends HtmlExtension {
  final Room room;
  const LinkifyHtmlExtension(this.room);

  @override
  InlineSpan build(ExtensionContext context) {
    if (context.node.attributes.containsKey("href")) {
      var uri = context.node.attributes["href"]!;
      var href = Uri.parse(uri);

      if (href.host == "matrix.to") {
        var result = MatrixClient.parseMatrixLink(href);
        if (result != null) {
          var mxid = result.$2;

          Widget? overrideWidget;
          if (result.$1 == MatrixLinkType.user) {
            var user = room.getMemberOrFallback(mxid);
            overrideWidget = MentionWidget(
              displayName: user.displayName,
              placeholderColor: user.defaultColor,
              avatar: user.avatar,
              onTap: () => LinkUtils.open(href,
                  clientId: room.client.identifier,
                  contextRoomId: room.identifier),
            );
          }

          if (result.$1 == MatrixLinkType.room ||
              result.$1 == MatrixLinkType.roomAlias) {
            var mentionedRoom = room.client.getRoom(mxid);
            mentionedRoom ??= room.client.getRoomByAlias(mxid);
            overrideWidget = MentionWidget(
              displayName: mentionedRoom?.displayName ?? mxid,
              placeholderColor:
                  mentionedRoom?.defaultColor ?? MatrixPeer.hashColor(mxid),
              avatar: mentionedRoom?.avatar,
              onTap: () => LinkUtils.open(href,
                  clientId: room.client.identifier,
                  contextRoomId: room.identifier),
            );
          }

          if (overrideWidget != null) {
            return WidgetSpan(
                child: Transform.translate(
                    offset: Offset(0, 2),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                      child: overrideWidget,
                    )));
          }
        }
      }

      return LinkSpan.create(context.node.text!,
          clientId: room.client.identifier,
          context: context.buildContext!,
          destination: Uri.parse(context.node.attributes["href"]!));
    }

    return TextSpan(
        children: TextUtils.linkifyString(context.node.text!,
            clientId: room.client.identifier, context: context.buildContext!));
  }

  @override
  bool matches(ExtensionContext context) {
    if (context.node.attributes.containsKey("href")) {
      return true;
    }

    return context.node is dom.Text &&
        TextUtils.containsUrl(context.node.text!);
  }

  @override
  Set<String> get supportedTags => {};
}

class SpoilerHtmlExtension extends HtmlExtension {
  bool hide = true;
  Function() onTap;

  SpoilerHtmlExtension(this.hide, this.onTap);

  @override
  InlineSpan build(ExtensionContext context) {
    var theme = Theme.of(context.buildContext!);
    var color = theme.textTheme.bodyMedium!.color;

    var recogniser = TapGestureRecognizer();
    recogniser.onTap = onTap;
    return TextSpan(
        text: context.node.text,
        recognizer: recogniser,
        style: TextStyle(
            color: color,
            backgroundColor: hide == true ? color : color!.withAlpha(20)));
  }

  @override
  bool matches(ExtensionContext context) {
    return context.attributes.containsKey("data-mx-spoiler");
  }

  @override
  Set<String> get supportedTags => {};
}

class MatrixImageExtension extends HtmlExtension {
  final double defaultDimension;

  final matrix.Client client;
  final Room room;
  const MatrixImageExtension(this.client, this.room,
      {this.defaultDimension = 64});

  @override
  Set<String> get supportedTags => {'img'};

  @override
  InlineSpan build(ExtensionContext context) {
    final mxcUrl = Uri.tryParse(context.attributes['src'] ?? '');

    if (mxcUrl == null) {
      return TextSpan(text: context.attributes['alt']);
    }

    if (mxcUrl.scheme != 'mxc' || !room.shouldPreviewMedia) {
      return LinkSpan.create(mxcUrl.toString(),
          clientId: room.client.identifier,
          destination: mxcUrl,
          context: context.buildContext!);
    }

    final width = double.tryParse(context.attributes['width'] ?? '');
    final height = double.tryParse(context.attributes['height'] ?? '');

    return WidgetSpan(
      child: SizedBox(
          width: width ?? height ?? defaultDimension,
          height: height ?? width ?? defaultDimension,
          child: Image(
            image: MatrixMxcImage(
              mxcUrl,
              client,
            ),
          )),
    );
  }
}
