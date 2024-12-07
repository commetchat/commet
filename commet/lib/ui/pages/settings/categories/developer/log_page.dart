import 'dart:async';

import 'package:commet/cache/error_log.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/ui/atoms/tiny_pill.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  int count = 0;

  StreamSubscription? sub;

  static const Map<String, TextStyle> ansiStyleMap = {
    "\x1b[30m": TextStyle(color: Colors.black), //	foreground black
    "\x1b[31m": TextStyle(color: Colors.redAccent), //	foreground red
    "\x1b[32m": TextStyle(color: Colors.greenAccent), //	foreground green
    "\x1b[33m": TextStyle(color: Colors.yellowAccent), //	foreground yellow
    "\x1b[34m": TextStyle(color: Colors.blueAccent), //	foreground blue
    "\x1b[35m": TextStyle(color: Colors.purpleAccent), //	foreground magenta
    "\x1b[36m": TextStyle(color: Colors.cyanAccent), //	foreground cyan
    "\x1b[37m": TextStyle(color: Colors.white), //	foreground white
    "\x1b[40m": TextStyle(backgroundColor: Colors.black), //	background black
    "\x1b[41m": TextStyle(backgroundColor: Colors.red), //	background red
    "\x1b[42m": TextStyle(backgroundColor: Colors.green), //	background green
    "\x1b[43m": TextStyle(backgroundColor: Colors.yellow), //	background yellow
    "\x1b[44m": TextStyle(backgroundColor: Colors.blue), //	background blue
    "\x1b[45m": TextStyle(backgroundColor: Colors.purple), //	background magenta
    "\x1b[46m": TextStyle(backgroundColor: Colors.cyan), //	background cyan
    "\x1b[47m": TextStyle(backgroundColor: Colors.white), //	background white
    "\x1b[0m": TextStyle(),
  };

  @override
  void initState() {
    sub = Log.log.onListUpdated.listen(onLogsUpdated);
    count = Log.log.length;
    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (context, index) {
        var item = Log.log[Log.log.length - index - 1];
        return buildLog(item, index);
      },
    );
  }

  Widget buildLog(LogEntry entry, int index) {
    IconData icon = Icons.info;

    Color color = Colors.white38;

    switch (entry.type) {
      case LogType.info:
        icon = Icons.info;
        break;
      case LogType.debug:
        icon = Icons.bug_report;
        color = Colors.amberAccent;
        break;
      case LogType.error:
        icon = Icons.error_outline;
        color = Colors.redAccent;
        break;
      case LogType.warning:
        color = Colors.amberAccent;
        icon = Icons.warning;
        break;
    }

    var background = index % 2 == 0
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Theme.of(context).colorScheme.surfaceContainerHigh;

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: InkWell(
        child: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5), color: background),
          child: InkWell(
            onTap: () => AdaptiveDialog.show(context,
                builder: (context) => logDetail(entry), title: entry.type.name),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (entry.count > 1)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: TinyPill("${entry.count}"),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(
                          icon,
                          size: 15,
                          color: color,
                        ),
                      ),
                      tiamat.Text.labelLow(entry.type.name),
                      const SizedBox(width: 10, child: tiamat.Seperator()),
                      tiamat.Text.labelLow(
                          DateFormat(DateFormat.HOUR_MINUTE_SECOND)
                              .format(entry.time.toLocal())),
                    ],
                  ),
                  Text.rich(
                      TextSpan(children: buildAnsiStyledTest(entry.content)))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> buildAnsiStyledTest(String text) {
    text = text.trim();
    List<InlineSpan> spans = List.empty(growable: true);
    int prevIndex = 0;
    var style = const TextStyle();
    for (int i = 0; i < text.length; i++) {
      for (var entry in ansiStyleMap.entries) {
        if (text.startsWith(entry.key, i)) {
          var sub = text.substring(prevIndex, i);
          i += entry.key.length;
          prevIndex = i;
          spans.add(TextSpan(text: sub, style: style));
          style = entry.value;
          break;
        }
      }
    }

    if (prevIndex <= text.length - 1) {
      spans.add(TextSpan(text: text.substring(prevIndex), style: style));
    }

    return spans;
  }

  Widget logDetail(LogEntry entry) {
    return SelectionArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entry is LogEntryException)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                child: tiamat.Button.secondary(
                  text: "Report Issue",
                  onTap: () => ErrorUtils.reportIssue(ErrorEntry(
                      stackTrace: entry.trace.toString(),
                      detail: entry.content,
                      lastOccurred: entry.time,
                      occurrences: 1)),
                ),
              ),
            Text.rich(TextSpan(children: buildAnsiStyledTest(entry.content))),
            if (entry is LogEntryException)
              Codeblock(text: entry.trace.toString()),
          ],
        ),
      ),
    );
  }

  void onLogsUpdated(event) {
    setState(() {
      count = Log.log.length;
    });
  }
}
