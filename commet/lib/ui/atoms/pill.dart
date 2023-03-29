import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class Pill extends StatelessWidget {
  final String identifier;
  final String url;
  final String displayText;
  final Future<Map<String, dynamic>>? future;
  final void Function()? onTap;
  final ImageProvider? image;

  const Pill({
    Key? key,
    required this.identifier,
    required this.url,
    required this.displayText,
    this.future,
    this.onTap,
    this.image,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: EdgeInsets.all(2),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withAlpha(200)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(displayText),
            ],
          ),
        ),
        onTap: () {},
      ),
    );
  }
}
