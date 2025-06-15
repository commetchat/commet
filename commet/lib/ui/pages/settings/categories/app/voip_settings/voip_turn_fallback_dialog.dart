import 'package:commet/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class VoipTurnFallbackDialog extends StatefulWidget {
  const VoipTurnFallbackDialog(this.homeserver, {super.key});
  final Uri homeserver;

  @override
  State<VoipTurnFallbackDialog> createState() => _VoipTurnFallbackDialogState();
}

class _VoipTurnFallbackDialogState extends State<VoipTurnFallbackDialog> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Markdown(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                data:
                    "Your homeserver `(${widget.homeserver})` is not configured to route calls. Would you like to fall back to a seperate server `(${preferences.fallbackTurnServer})` to handle routing?"),
            const SizedBox(
              height: 20,
            ),
            const tiamat.Text.labelLow(
                "Without a server to route, calls cannot be connected. Your IP Address will be shared with the fallback server"),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Expanded(
                  child: tiamat.Button(
                    text: "Use fallback server",
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: tiamat.Button.secondary(
                      text: "Cancel call",
                      onTap: () => Navigator.of(context).pop(false)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
