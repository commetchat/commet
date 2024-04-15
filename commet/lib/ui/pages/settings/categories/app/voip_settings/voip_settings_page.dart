import 'package:commet/ui/pages/settings/categories/app/voip_settings/voip_debug_settings.dart';
import 'package:flutter/widgets.dart';

class VoipSettingsPage extends StatefulWidget {
  const VoipSettingsPage({super.key});

  @override
  State<VoipSettingsPage> createState() => _VoipSettingsPage();
}

class _VoipSettingsPage extends State<VoipSettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const VoipDebugSettings();
  }
}
