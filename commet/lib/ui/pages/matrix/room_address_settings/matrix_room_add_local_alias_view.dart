import 'package:commet/utils/debounce.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixRoomAddLocalAliasView extends StatefulWidget {
  const MatrixRoomAddLocalAliasView(
      this.homeserver, this.isAliasAvailable, this.createAlias,
      {super.key});
  final String homeserver;
  final Future<bool> Function(String alias) isAliasAvailable;
  final Future<String?> Function(String alias) createAlias;

  @override
  State<MatrixRoomAddLocalAliasView> createState() =>
      _MatrixRoomAddLocalAliasViewState();
}

class _MatrixRoomAddLocalAliasViewState
    extends State<MatrixRoomAddLocalAliasView> {
  TextEditingController controller = TextEditingController();
  Debouncer debouncer = Debouncer(delay: const Duration(milliseconds: 500));

  bool? isAvailable;
  bool createLoading = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(onTextChanged);
  }

  void onTextChanged() {
    setState(() {
      isAvailable = null;
    });

    if (controller.text.isEmpty) {
      debouncer.cancel();
    } else {
      debouncer.run(checkAvailability);
    }
  }

  Future<void> checkAvailability() async {
    var result = await widget.isAliasAvailable(controller.text);
    setState(() {
      isAvailable = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tiamat.TextInput(
          controller: controller,
          placeholder: "my-room",
          suffixText: ":${widget.homeserver}",
          prefixText: "#",
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isAvailable == false)
              const tiamat.Text.error("Alias already in use"),
            if (isAvailable == true)
              const tiamat.Text.label("Alias is available!"),
            if (isAvailable == null && controller.text.isEmpty) Container(),
            if (isAvailable == null && controller.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                    width: 15, height: 15, child: CircularProgressIndicator()),
              ),
            tiamat.Button(
              text: "Create!",
              onTap: submit,
              isLoading: createLoading,
            )
          ],
        )
      ],
    );
  }

  Future<void> submit() async {
    if (isAvailable != true) {
      return;
    }

    setState(() {
      createLoading = true;
    });

    var text = controller.text;

    var result = await widget.createAlias(text);

    if (result != null) {
      setState(() {
        createLoading = false;
      });

      if (mounted) Navigator.of(context).pop(result);
    } else {
      setState(() {
        isAvailable = false;
      });
    }
  }
}
