import 'package:commet/utils/emoji/emoji_pack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class AccountEmojiView extends StatefulWidget {
  const AccountEmojiView(this.globalPacks, {super.key});
  final List<EmoticonPack> globalPacks;

  @override
  State<AccountEmojiView> createState() => _AccountEmojiViewState();
}

class _AccountEmojiViewState extends State<AccountEmojiView> {
  @override
  Widget build(BuildContext context) {
    return tiamat.Panel(
      header: "Global Packs",
      mode: tiamat.TileType.surfaceLow1,
      child: Column(
          children: widget.globalPacks.map((e) => packSummary(e)).toList()),
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
              child: tiamat.Text.labelEmphasised(pack.displayName),
            ),
          ],
        ),
      ),
    );
  }
}
