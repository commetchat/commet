// ignore: implementation_imports
import 'package:intl/src/intl_helpers.dart';

/// User programs should call this before using [localeName] for messages.
Future<bool> initializeMessagesDebug() async {
  initializeInternalMessageLookup(() => DebugLookup());
  return Future.value(true);
}

class DebugLookup implements MessageLookup {
  @override
  void addLocale(String localeName, Function findLocale) {}

  @override
  String? lookupMessage(String? messageText, String? locale, String? name,
      List<Object>? args, String? meaning,
      {MessageIfAbsent? ifAbsent}) {
    return "$name";
  }
}
