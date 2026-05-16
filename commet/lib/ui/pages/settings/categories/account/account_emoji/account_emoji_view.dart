import 'dart:async';

import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/main.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class AccountEmojiView extends StatefulWidget {
  const AccountEmojiView(this.component, {super.key});
  final EmoticonComponent component;
  @override
  State<AccountEmojiView> createState() => _AccountEmojiViewState();
}

class _AccountEmojiViewState extends State<AccountEmojiView> {
  late List<EmoticonPack> globalPacks;
  StreamSubscription? sub;

  @override
  void initState() {
    sub = widget.component.onStateChanged.listen((_) => updateState());
    updateState();
    super.initState();
  }

  void updateState() {
    setState(() {
      globalPacks = widget.component.globalPacks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        tiamat.Panel(
          header: "Favorite Packs",
          mode: tiamat.TileType.surfaceContainerLow,
          child:
              Column(children: globalPacks.map((e) => packSummary(e)).toList()),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (pack.image != null)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Image(
                      image: pack.image!,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      tiamat.Text.labelEmphasised(pack.displayName),
                      tiamat.Text.labelLow(preferences.developerMode.value
                          ? "${pack.ownerDisplayName} - (${pack.ownerId})"
                          : pack.ownerDisplayName),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: tiamat.IconButton(
                icon: Icons.heart_broken,
                onPressed: () => pack.markAsGlobal(false),
              ),
            )
          ],
        ),
      ),
    );
  }
}
