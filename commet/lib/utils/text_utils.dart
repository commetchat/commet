import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/rich_text/spans/link.dart';
import 'package:flutter/material.dart';
import 'emoji/emoji_matcher.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter/material.dart' as material;

final _urlRegex = RegExp(
  r'(?:(?:https?):\/\/|www\.)(?:\([-A-Z0-9+&@#/%=~_|$?!:,.]*\)|[-A-Z0-9+&@#/%=~_|$?!:,.])*(?:\([-A-Z0-9+&@#/%=~_|$?!:,.]*\)|[A-Z0-9+&@#/%=~_|$])',
  caseSensitive: false,
  dotAll: true,
);

enum NewPasswordResult { valid, tooShort, noNumbers, noSymbols, noMixedCase }

class TextUtils {
  static bool isEmoji(String text) {
    var matches = EmojiMatcher.find(text);
    if (matches.length != 1) return false;
    return matches.single.start == 0 && matches.single.end == text.length;
  }

  static String linkifyStringHtml(String text) {
    var matches = _urlRegex.allMatches(text);
    List<String> urlsToReplace = List.empty(growable: true);

    for (int i = 0; i < matches.length; i++) {
      var match = matches.elementAt(i);
      var link = text.substring(match.start, match.end);

      if (!urlsToReplace.contains(link)) {
        urlsToReplace.add(link);
      }
    }

    for (var link in urlsToReplace) {
      text = text.replaceAll(link, '<a href="$link">$link</a>');
    }

    return text;
  }

  static bool containsUrl(String text) {
    return _urlRegex.hasMatch(text);
  }

  static List<InlineSpan> linkifyString(String text,
      {TextStyle? style,
      required BuildContext context,
      required String clientId}) {
    var matches = _urlRegex.allMatches(text);
    return formatMatches(
      matches,
      text,
      style: style,
      builder: (matchedText, theme) {
        return LinkSpan.create(matchedText,
            clientId: clientId,
            context: context,
            destination: Uri.parse(matchedText),
            style: style);
      },
    );
  }

  static List<Uri>? findUrls(String text) {
    var matches = _urlRegex.allMatches(text);
    if (matches.isEmpty) return null;

    return matches
        .map((e) => Uri.parse(text.substring(e.start, e.end)))
        .toList();
  }

  static List<InlineSpan> formatMatches(
      Iterable<RegExpMatch> matches, String text,
      {required InlineSpan Function(String matchedText, TextStyle? theme)
          builder,
      TextStyle? style}) {
    if (matches.isEmpty) return [TextSpan(text: text, style: style)];

    List<InlineSpan> span = List.empty(growable: true);
    for (int i = 0; i < matches.length; i++) {
      var match = matches.elementAt(i);

      String? pre;

      if (i == 0 && match.start > 0) {
        pre = text.substring(0, match.start);
      } else if (i > 0) {
        var start = match.start;
        var end = matches.elementAt(i - 1).end;

        if (start != end) {
          var previous = matches.elementAt(i - 1);
          pre = text.substring(previous.end, match.start);
        }
      }

      if (pre != null) {
        span.add(TextSpan(text: pre, style: style));
      }

      span.add(builder(text.substring(match.start, match.end), style));
    }

    if (matches.last.end != text.length) {
      span.add(TextSpan(text: text.substring(matches.last.end), style: style));
    }

    return span;
  }

  static NewPasswordResult isValidPassword(
    String password, {
    bool forceDigits = false,
    int? forceLength,
    bool forceSpecialCharacter = false,
  }) {
    if (forceLength != null) {
      if (password.length < forceLength) return NewPasswordResult.tooShort;
    }

    if (forceDigits) {
      if (!password.characters.any((char) => int.tryParse(char) != null)) {
        return NewPasswordResult.noNumbers;
      }
    }

    if (forceSpecialCharacter) {
      if (!password.characters.any(
          (char) => ("!@#\$%^&*()_+`{}|:\"<>?/.,';][=-\\").contains(char))) {
        return NewPasswordResult.noSymbols;
      }
    }

    return NewPasswordResult.valid;
  }

  static String timestampToLocalizedTime(DateTime time, BuildContext context) {
    var difference = DateTime.now().difference(time);

    if (difference.inDays == 0) {
      return MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay.fromDateTime(time));
    }

    if (difference.inDays < 365) {
      return intl.DateFormat(intl.DateFormat.MONTH_WEEKDAY_DAY)
          .format(time.toLocal());
    }

    return intl.DateFormat(intl.DateFormat.YEAR_MONTH_WEEKDAY_DAY)
        .format(time.toLocal());
  }

  static String timestampToLocalizedTimeSpecific(DateTime time, context) {
    return intl.DateFormat().format(time.toLocal());
  }

  static String formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return "${duration.inSeconds}s";
    }

    if (duration.inMinutes < 60) {
      return "${duration.inMinutes.remainder(60)}:${(duration.inSeconds.remainder(60))}";
    }
    return "${duration.inHours}:${duration.inMinutes.remainder(60)}:${(duration.inSeconds.remainder(60))}";
  }

  static String readableFileSize(num number, {bool base1024 = true}) {
    const List<String> affixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    const useBase1024 = true;
    const int round = 2;

    // ignore: dead_code
    num divider = useBase1024 ? 1024 : 1000;

    num size = number;
    num runningDivider = divider;
    num runningPreviousDivider = 0;
    int affix = 0;

    while (size >= runningDivider && affix < affixes.length - 1) {
      runningPreviousDivider = runningDivider;
      runningDivider *= divider;
      affix++;
    }

    String result =
        (runningPreviousDivider == 0 ? size : size / runningPreviousDivider)
            .toStringAsFixed(round);

    //Check if the result ends with .00000 (depending on how many decimals) and remove it if found.
    if (result.endsWith("0" * round))
      result = result.substring(0, result.length - round - 1);

    return "$result ${affixes[affix]}";
  }

  static String redactSensitiveInfo(String text) {
    if (clientManager != null) {
      for (final client in clientManager!.clients) {
        if (client is MatrixClient) {
          var token = client.getMatrixClient().accessToken;

          if (token != null) {
            text = text.replaceAll(token, "[REDACTED ACCESS TOKEN]");
          }
        }
      }
    }

    return text;
  }
}
