import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../config/app_config.dart';

class Seperator extends StatelessWidget {
  const Seperator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(s(8.0)),
      child: Divider(
        height: s(1),
      ),
    );
  }
}
