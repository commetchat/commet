import 'package:flutter/cupertino.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoleView extends StatelessWidget {
  const RoleView({super.key, required this.name, this.icon, this.powerLevel});

  final IconData? icon;
  final String name;
  final int? powerLevel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Tile.low2(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon!),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: tiamat.Text.labelEmphasised(name),
                ),
                if (powerLevel != null) tiamat.Text.tiny('${powerLevel!}')
              ],
            ),
          ),
        ),
      ),
    );
  }
}
