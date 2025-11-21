import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:matrix_widget_api/capabilities.dart';
import 'package:matrix_widget_api/matrix_widget_api.dart';
import 'package:matrix_widget_api/types.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var parameters = Uri.parse(Uri.base.fragment).queryParameters;

    Brightness? themeBrightness = null;
    if (parameters["theme"] == "dark") themeBrightness = Brightness.dark;
    if (parameters["theme"] == "light") themeBrightness = Brightness.light;

    return MaterialApp(
      title: "Example Widget",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: themeBrightness ?? Brightness.light,
        ),
      ),
      home: const MyHomePage(title: 'Flutter Matrix Widget'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late MatrixWidgetApiWeb api;
  String userId = "";
  String params = "";

  @override
  void initState() {
    var parameters = Uri.parse(Uri.base.fragment).queryParameters;

    params = JsonEncoder.withIndent("  ").convert(parameters);
    userId = parameters["userId"] ?? "Unknown User Id";

    super.initState();
    api = MatrixWidgetApiWeb(
      parameters["widgetId"] ?? "Unknown Widget ID",
      userId: userId,
    );

    api.start();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });

    api.sendAction(FromWidgetAction.sendEvent, {
      "content": {
        "msgtype": "m.text",
        "body": "I pressed the button $_counter times",
      },
      "type": "m.room.message",
    });
  }

  void requestPermission() {
    api.requestCapabilities([
      MatrixCapability.requiresClient,
      MatrixCapability.sendEvent("m.room.message"),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
              onPressed: requestPermission,
              child: Text("Request Permissions"),
            ),
            Text(params),
            Text("Hello, ${userId}!!!"),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
