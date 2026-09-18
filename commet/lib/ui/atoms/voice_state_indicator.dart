import 'package:commet/client/components/activities/activities_component.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Whether a voice channel member has silenced themselves, shown after their
/// name in the room list: a crossed-out headset while deafened, a crossed-out
/// microphone while only muted. Members whose client does not report it show
/// nothing rather than a wrong icon.
class VoiceStateIndicator extends StatelessWidget {
  const VoiceStateIndicator(this.state, {super.key});

  final Set<VoiceState> state;

  String get tooltipVoiceMuted => Intl.message("Microphone muted",
      name: "tooltipVoiceMuted",
      desc:
          "Tooltip of the muted icon next to a voice channel member in the room list");

  String get tooltipVoiceDeafened => Intl.message("Deafened",
      name: "tooltipVoiceDeafened",
      desc:
          "Tooltip of the deafened icon next to a voice channel member in the room list");

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.of(context);

    // Deafened first: it implies muted, and is the stronger statement.
    if (state.contains(VoiceState.deafened)) {
      return Tooltip(
        message: tooltipVoiceDeafened,
        child: Icon(Icons.headset_off_rounded, size: 16, color: colors.error),
      );
    }

    if (state.contains(VoiceState.muted)) {
      return Tooltip(
        message: tooltipVoiceMuted,
        child: Icon(Icons.mic_off_rounded,
            size: 16, color: colors.onSurfaceVariant),
      );
    }

    return const SizedBox.shrink();
  }
}
