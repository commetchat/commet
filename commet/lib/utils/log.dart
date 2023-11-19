import 'dart:async';
import 'dart:io';

import 'package:commet/main.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

enum LogType {
  info,
  important,
  critical,
}

class LogEvent {
  final String body;
  late final DateTime time;
  late final LogType type;

  LogEvent({required this.body, this.type = LogType.info}) {
    time = DateTime.now();
  }
}

class Log {
  static final NotifyingList<LogEvent> events =
      NotifyingList.empty(growable: true);

  static ZoneSpecification? zone;

  static void init(void Function() entryPoint) {
    zone = ZoneSpecification(
      print: (self, parent, zone, line) {
        parent.print(zone, line);
      },
    );

    return Zone.current.fork(specification: zone!).run<void>(entryPoint);
  }
}

void logi(Object? object) {}
