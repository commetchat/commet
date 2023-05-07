import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class NotificationBadge extends StatelessWidget {
  const NotificationBadge(this.count, {super.key, this.size = 15});
  final double size;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
            child: Center(
              child: Text(
                count > 9 ? "9+" : count.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.white,
                    shadows: [BoxShadow(blurRadius: 2)]),
              ),
            ),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size / 2),
                color: Colors.red.shade600)));
  }
}
