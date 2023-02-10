import 'package:flutter/material.dart';

class IconButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final void Function() onPressed;

  const IconButton({
    required Key key,
    required this.icon,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          children: [
            Icon(icon),
            SizedBox(width: 8.0),
            Text(text),
          ],
        ),
      ),
    );
  }
}
