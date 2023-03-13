import 'package:commet/generated/l10n.dart';
import 'package:flutter/widgets.dart';

import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class AddSpaceDialog extends StatefulWidget {
  const AddSpaceDialog({super.key});

  @override
  State<AddSpaceDialog> createState() => _AddSpaceDialogState();
}

class _AddSpaceDialogState extends State<AddSpaceDialog> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      width: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          tiamat.Text.labelEmphasised(T.of(context).createNewSpace),
          const Seperator(),
          tiamat.Text.labelEmphasised(T.of(context).joinExistingSpace)
        ],
      ),
    );
  }
}
