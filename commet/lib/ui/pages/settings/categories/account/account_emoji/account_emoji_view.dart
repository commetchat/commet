import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class AccountEmojiView extends StatefulWidget {
  const AccountEmojiView(this.globalPacks, this.personalPacks, {super.key});
  final List<EmoticonPack> globalPacks;
  final List<EmoticonPack> personalPacks;
  @override
  State<AccountEmojiView> createState() => _AccountEmojiViewState();
}

class _AccountEmojiViewState extends State<AccountEmojiView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        tiamat.Panel(
          header: "Global Packs",
          mode: tiamat.TileType.surfaceContainerLow,
          child: Column(
              children: widget.globalPacks.map((e) => packSummary(e)).toList()),
        ),
      ],
    );
  }

  Widget packSummary(EmoticonPack pack) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            if (pack.image != null)
              Image(
                image: pack.image!,
                filterQuality: FilterQuality.medium,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  tiamat.Text.labelEmphasised(pack.displayName),
                  tiamat.Text.labelLow(preferences.developerMode
                      ? "${pack.ownerDisplayName} - (${pack.ownerId})"
                      : pack.ownerDisplayName),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
