import 'package:commet/main.dart';
import 'package:commet/ui/pages/developer/app_inspector/value_reflector_widget.dart';
import 'package:flutter/material.dart';

class AppInspectorPage extends StatelessWidget {
  const AppInspectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [ValueReflectorWidget(value: clientManager!)],
        ),
      ),
    );
  }
}
