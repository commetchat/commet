import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoleView extends StatelessWidget {
  const RoleView({super.key, required this.name, this.icon, this.powerLevel});

  final IconData? icon;
  final String name;
  final int? powerLevel;

  @override
  Widget build(BuildContext context) {
    var bg = Theme.of(context).colorScheme.surfaceContainerHigh;
    var fg = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: bg,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(
                    icon!,
                    color: fg,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: tiamat.Text.labelEmphasised(name),
                ),
                if (powerLevel != null)
                  tiamat.Text.tiny(
                    '${powerLevel!}',
                    color: fg,
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
