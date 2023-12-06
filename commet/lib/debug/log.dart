import 'dart:async';

import 'package:commet/main.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/widgets.dart';

enum LogType { info, debug, error, warning }

class LogEntry {
  late DateTime _time;
  LogType type;
  DateTime get time => _time;
  String content;

  LogEntry(this.type, this.content) {
    _time = DateTime.now();
  }
}

class LogEntryException extends LogEntry {
  Object exception;
  StackTrace? trace;

  LogEntryException(super.type, super.content, this.exception, this.trace);
}

class Log {
  static final NotifyingList<LogEntry> log =
      NotifyingList.empty(growable: true);

  static ZoneSpecification spec = ZoneSpecification(
    print: (self, parent, zone, line) {
      parent.print(zone, line);

      if (!preferences.isInit || preferences.developerMode == true) {
        log.add(LogEntry(LogType.info, line));
      }
    },
    errorCallback: (self, parent, zone, error, stackTrace) {
      parent.print(zone, "ERROR CALLBACK");
      parent.print(zone, error.toString());
      parent.print(zone, stackTrace?.toString() ?? "");
      log.add(LogEntryException(
          LogType.error, error.toString(), error, stackTrace));
      return null;
    },
    handleUncaughtError: (self, parent, zone, error, stackTrace) {
      parent.print(zone, "HandleUncaughtError");
      log.add(LogEntryException(
          LogType.error, error.toString(), error, stackTrace));
    },
  );

  static String _formatString(String logsStr, LogType type) {
    switch (type) {
      case LogType.error:
        logsStr = '\x1B[31m$logsStr\x1B[0m';
        break;
      case LogType.warning:
        logsStr = '\x1B[33m$logsStr\x1B[0m';
        break;
      case LogType.info:
        logsStr = '\x1B[32m$logsStr\x1B[0m';
        break;
      case LogType.debug:
        logsStr = '\x1B[34m$logsStr\x1B[0m';
        break;
    }

    return '[Commet] $logsStr';
  }

  static void _print(LogEntry entry) {
    log.add(entry);
    // ignore: avoid_print
    print(entry.content);
  }

  static void i(Object o) {
    var str = _formatString(o.toString(), LogType.info);
    _print(LogEntry(LogType.info, str));
  }

  static void e(Object o) {
    var str = _formatString(o.toString(), LogType.error);
    _print(LogEntry(LogType.error, str));
  }

  static void d(Object o) {
    var str = _formatString(o.toString(), LogType.debug);
    _print(LogEntry(LogType.debug, str));
  }

  static void w(Object o) {
    var str = _formatString(o.toString(), LogType.warning);
    _print(LogEntry(LogType.warning, str));
  }

  static void onError(Object object, StackTrace trace) {
    log.add(LogEntryException(LogType.error, object.toString(), object, trace));
  }

  static Function(FlutterErrorDetails)? _previousReporter;
  static Function(FlutterErrorDetails) getFlutterErrorReporter(
      Function(FlutterErrorDetails)? current) {
    _previousReporter = current;
    return _onFlutterError;
  }

  static void _onFlutterError(FlutterErrorDetails details) {
    String? info;

    if (details.stack != null) {
      var str = details.stack.toString();
      var match = RegExp(r"([a-zA-Z0-9_]*)\.([a-zA-Z0-9_]*)").firstMatch(str);
      if (match != null) {
        info = str.substring(match.start, match.end);
      }
    }
    log.add(LogEntryException(
        LogType.error,
        "${details.exception.toString()}${info != null ? " ($info)" : ""}",
        details.exception,
        details.stack));

    _previousReporter?.call(details);
  }
}
