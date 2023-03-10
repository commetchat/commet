import 'package:commet/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../atoms/seperator.dart';

class AddSpaceDialog extends StatefulWidget {
  const AddSpaceDialog({super.key});

  @override
  State<AddSpaceDialog> createState() => _AddSpaceDialogState();
}

class _AddSpaceDialogState extends State<AddSpaceDialog> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [Text(T.of(context).createNewSpace), Seperator(), Text(T.of(context).joinExistingSpace)],
    );
  }
}
