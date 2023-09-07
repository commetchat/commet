import 'package:commet/main.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:tiamat/tiamat.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPage();
}

class _GeneralSettingsPage extends State<GeneralSettingsPage> {
  bool enableTenor = false;

  String get labelThirdPartyServicesTitle =>
      Intl.message("Third party services",
          desc: "Header for the third party services section in settings",
          name: "labelThirdPartyServicesTitle");

  String get labelGifSearchToggle => Intl.message("Gif search",
      desc: "Label for the toggle for enabling and disabling gif search",
      name: "labelGifSearchToggle");

  String labelGifSearchDescription(proxyUrl) => Intl.message(
      "Enable use of Tenor gif search. Requests will be proxied via $proxyUrl",
      desc: "Explains that gifs will be fetched via proxy",
      args: [proxyUrl],
      name: "labelGifSearchDescription");

  @override
  void initState() {
    enableTenor = preferences.tenorGifSearchEnabled;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      header: labelThirdPartyServicesTitle,
      mode: TileType.surfaceLow2,
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tiamat.Text.labelEmphasised(labelGifSearchToggle),
                  tiamat.Text.labelLow(
                      labelGifSearchDescription(preferences.gifProxyUrl))
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
