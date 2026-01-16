import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class VoiceChatCreatorDescription extends StatelessWidget {
  const VoiceChatCreatorDescription({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 24,
      children: [
        tiamat.Text.labelLow(
            "A dedicated room for voice calls, for two or more people"),
        Container(
          decoration: BoxDecoration(
            color: ColorScheme.of(context).surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    spacing: 12,
                    children: [
                      Icon(Icons.volume_up),
                      Text("General",
                          style: TextTheme.of(context)
                              .headlineSmall
                              ?.copyWith(fontSize: 20))
                    ],
                  ),
                ),
                buildVoiceChatMember(
                  context,
                  image: AssetImage("assets/images/placeholders/avatar1.jpg"),
                  name: "pluto",
                  color: Colors.pinkAccent,
                ),
                SizedBox(
                  height: 12,
                ),
                buildVoiceChatMember(
                  context,
                  image: AssetImage("assets/images/placeholders/avatar2.jpg"),
                  name: "luna",
                  color: Colors.cyan,
                  mute: true,
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget buildVoiceChatMember(
    BuildContext context, {
    required ImageProvider image,
    required String name,
    required Color color,
    bool mute = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ColorScheme.of(context).surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          spacing: 16,
          children: [
            Icon(mute ? Icons.mic_off : Icons.mic),
            tiamat.Avatar(
              image: image,
            ),
            tiamat.Text(
              name,
              type: tiamat.TextType.name,
              color: color,
              autoAdjustBrightness: true,
            )
          ],
        ),
      ),
    );
  }
}

class VoiceChatCreatorForm extends StatefulWidget {
  const VoiceChatCreatorForm({super.key});

  @override
  State<VoiceChatCreatorForm> createState() => _VoiceChatCreatorFormState();
}

class _VoiceChatCreatorFormState extends State<VoiceChatCreatorForm> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
