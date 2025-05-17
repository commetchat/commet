import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class MiniCallMenuConnected extends StatelessWidget {
  const MiniCallMenuConnected(
      {required this.roomDisplayName,
      this.onHangUp,
      this.onToggleMute,
      this.isMicrophoneMuted = false,
      super.key});
  final Function()? onHangUp;
  final Function()? onToggleMute;
  final bool isMicrophoneMuted;
  final String roomDisplayName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          tiamat.Text.body(roomDisplayName),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                tiamat.IconButton(
                  icon: isMicrophoneMuted ? Icons.mic_off : Icons.mic,
                  size: 20,
                  onPressed: onToggleMute,
                ),
                tiamat.IconButton(
                    icon: Icons.call_end,
                    iconColor: Theme.of(context).colorScheme.error,
                    onPressed: onHangUp,
                    size: 20),
              ],
            ),
          )
        ],
      ),
    );
  }
}
