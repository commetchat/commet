import 'package:commet/config/platform_utils.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/system_wide_shortcuts/system_wide_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class KeyboardHookShortcutsSettingsPage extends StatefulWidget {
  const KeyboardHookShortcutsSettingsPage({super.key});

  @override
  State<KeyboardHookShortcutsSettingsPage> createState() =>
      _KeyboardHookShortcutsSettingsPageState();
}

class _KeyboardHookShortcutsSettingsPageState
    extends State<KeyboardHookShortcutsSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return tiamat.Panel(
      mode: tiamat.TileType.surfaceContainerLow,
      header: "Configure Shortcuts",
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var shortcut in SystemWideShortcuts.shortcuts.entries)
            Material(
              color: ColorScheme.of(context).surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () async {
                  var key = await AdaptiveDialog.show<HotKey>(context,
                      dismissible: false, builder: (context) {
                    HotKey? hotkey = shortcut.value.hotkey;

                    return Column(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        tiamat.Text.largeTitle("Press A Key Combination"),
                        SizedBox(
                          height: 50,
                          child: Center(
                            child: HotKeyRecorder(
                                initalHotKey: hotkey,
                                onHotKeyRecorded: (k) {
                                  hotkey = k;
                                }),
                          ),
                        ),
                        tiamat.Button(
                          text: "Submit",
                          onTap: () => Navigator.of(context).pop(hotkey),
                        ),
                        tiamat.Button.secondary(
                          text: "Clear Hotkey",
                          onTap: () => Navigator.of(context).pop(null),
                        )
                      ],
                    );
                  });

                  if (PlatformUtils.isLinux) {
                    if (key?.modifiers?.contains(HotKeyModifier.shift) ==
                        true) {
                      await AdaptiveDialog.show(context,
                          title: "Warning",
                          builder: (_) => SizedBox(
                                width: 500,
                                child: Column(
                                  children: [
                                    tiamat.Text.label(
                                        "Hotkeys using 'Shift' as a modifier may be unreliable on Linux, consider using a different key combination"),
                                    tiamat.Button.secondary(
                                      text: "Okay!",
                                      onTap: () => Navigator.of(context).pop(),
                                    )
                                  ],
                                ),
                              ));
                    }
                  }

                  if (key != null) {
                    await shortcut.value.setHotkey(key);
                  } else {
                    await shortcut.value.clearHotkey();
                  }

                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    spacing: 12,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      tiamat.Text(shortcut.value.getDisplayName()),
                      if (shortcut.value.hotkey != null)
                        HotKeyVirtualView(hotKey: shortcut.value.hotkey!)
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}
