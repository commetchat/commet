import 'package:commet/main.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/pages/developer/app_inspector/value_reflector_widget.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class AppInspectorPage extends StatelessWidget {
  const AppInspectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: ScaledSafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: tiamat.CircleButton(
                  icon: Icons.arrow_back,
                  radius: 27,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: tiamat.Text.body(
                    "Warning: This inspector allows you to view lots of information that would typically be hidden, some of which could be sensitive. It is recommended that you do not view this page if your screen may be visible to others\n\nWhile effort has been made to redact sensitive information, we cannot guarantee that we have caught everything. Continue at your own risk."),
              ),
              ValueReflectorWidget(value: clientManager!)
            ],
          ),
        ),
      ),
    );
  }
}
