import 'package:commet/main.dart';
import 'package:flutter/widgets.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPage();
}

class _GeneralSettingsPage extends State<GeneralSettingsPage> {
  bool enableTenor = false;

  @override
  void initState() {
    enableTenor = preferences.tenorGifSearchEnabled;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      header: "Third party services",
      mode: TileType.surfaceLow2,
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const tiamat.Text.labelEmphasised("Gif search"),
                  tiamat.Text.labelLow(
                      "Enable use of Tenor gif search. Requests will be proxied via ${preferences.gifProxyUrl}")
                ],
              ),
            ),
            tiamat.Switch(
              state: enableTenor,
              onChanged: (value) async {
                setState(() {
                  enableTenor = value;
                });
                await preferences.setTenorGifSearch(value);
                setState(() {
                  enableTenor = preferences.tenorGifSearchEnabled;
                });
              },
            )
          ],
        )
      ]),
    );
  }
}
