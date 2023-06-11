import 'package:commet/ui/atoms/code_block.dart';
import 'package:flutter/material.dart';

class RoomDeveloperSettingsView extends StatelessWidget {
  final String developerInfo;
  const RoomDeveloperSettingsView(this.developerInfo, {super.key});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Codeblock(
        language: "json",
        text: developerInfo,
      ),
    );
  }
}
