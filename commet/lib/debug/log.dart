import 'dart:async';

import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/foundation.dart';

enum LogType { info, debug, error, warning }

class LogEntry {
  late DateTime _time;
  LogType type;
  DateTime get time => _time;
  String rawContent;
  int count = 1;

  LogEntry(this.type, this.rawContent) {
    _time = DateTime.now();
  }

  // Log content with sensitive information removed
  String get content {
    return TextUtils.redactSensitiveInfo(rawContent);
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

  static String prefix = "";

  static void add(LogEntry entry) {
    if (log.isNotEmpty &&
        log.last.type == entry.type &&
        log.last.rawContent == entry.rawContent) {
      log.last.count += 1;
    } else {
      log.add(entry);
    }
  }

  static ZoneSpecification spec = ZoneSpecification(
    print: (self, parent, zone, line) {
      parent.print(zone, "($prefix) $line");

      if (line.startsWith("[Commet")) {
        return;
      }

      if (!preferences.isInit || preferences.developerMode == true) {
        add(LogEntry(LogType.info, line));
      }
    },
    errorCallback: (self, parent, zone, error, stackTrace) {
      parent.print(zone, "ERROR CALLBACK");
      parent.print(zone, error.toString());
      parent.print(zone, stackTrace?.toString() ?? "");
      String? info =
          stackTrace != null ? getDetailFromStackTrace(stackTrace) : null;
      add(LogEntryException(
          LogType.error,
          "${error.toString()}${info != null ? " ($info)" : ""}",
          error,
          stackTrace));
      return null;
    },
    handleUncaughtError: (self, parent, zone, error, stackTrace) {
      parent.print(zone, "HandleUncaughtError");
      String? info = getDetailFromStackTrace(stackTrace);
      add(LogEntryException(
          LogType.error, "${error.toString()} ($info)", error, stackTrace));
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
    add(entry);

    // ignore: avoid_print
    print(entry.rawContent);
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
    if (BuildConfig.DEBUG || kDebugMode) {
      var str = _formatString(o.toString(), LogType.debug);
      _print(LogEntry(LogType.debug, str));
    }
  }

  static void w(Object o) {
    var str = _formatString(o.toString(), LogType.warning);
    _print(LogEntry(LogType.warning, str));
  }

  static void onError(Object object, StackTrace trace, {String? content}) {
    String? info = getDetailFromStackTrace(trace);
    var entry = LogEntryException(LogType.error,
        content ?? "${object.toString()} ($info)", object, trace);
    _print(entry);
  }

  static Function(FlutterErrorDetails)? _previousReporter;
  static Function(FlutterErrorDetails) getFlutterErrorReporter(
      Function(FlutterErrorDetails)? current) {
    _previousReporter = current;
    return _onFlutterError;
  }

  static void _onFlutterError(FlutterErrorDetails details) {
    String? info =
        details.stack != null ? getDetailFromStackTrace(details.stack!) : null;
    add(LogEntryException(
        LogType.error,
        "${details.exception.toString()}${info != null ? " ($info)" : ""}",
        details.exception,
        details.stack));

    _previousReporter?.call(details);
  }

  static String? getDetailFromStackTrace(StackTrace stack) {
    String? info;

    var str = stack.toString();
    var match = RegExp(r"([a-zA-Z0-9_]*)\.([a-zA-Z0-9_]*)").firstMatch(str);
    if (match != null) {
      info = str.substring(match.start, match.end);
    }

    return info;
  }
}
