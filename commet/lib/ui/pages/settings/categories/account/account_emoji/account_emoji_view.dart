import 'package:commet/ui/pages/settings/categories/room/emoji_packs/room_emoji_pack_settings_view.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
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
          mode: tiamat.TileType.surfaceLow2,
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
              child: tiamat.Text.labelEmphasised(pack.displayName),
            ),
          ],
        ),
      ),
    );
  }
}
