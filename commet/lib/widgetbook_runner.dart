import 'package:commet/main.widgetbook.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import 'generated/l10n.dart';

void main() async {
  runApp(const WidgetbookRunner());
}

class WidgetbookRunner extends StatelessWidget {
  const WidgetbookRunner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Commet',
      localizationsDelegates: const [
        T.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: T.delegate.supportedLocales,
      home: const HotReload(),
    );
  }
}
