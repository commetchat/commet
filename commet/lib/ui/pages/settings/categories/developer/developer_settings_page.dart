import 'package:commet/main.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class DeveloperSettingsPage extends StatefulWidget {
  const DeveloperSettingsPage({super.key});

  @override
  State<DeveloperSettingsPage> createState() => _DeveloperSettingsPageState();
}

class _DeveloperSettingsPageState extends State<DeveloperSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ExpansionTile(
            title: const tiamat.Text.labelEmphasised("Performance"),
            initiallyExpanded: false,
            backgroundColor:
                Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
            collapsedBackgroundColor:
                Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
            children: diagnostics.results
                .map((e) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: tiamat.Text.labelEmphasised(e.name)),
                          tiamat.Text.label("${e.time.inMilliseconds}ms")
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
