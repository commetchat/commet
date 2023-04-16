import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixUIARequestView extends StatefulWidget {
  const MatrixUIARequestView(this.state,
      {this.onSubmitAuthentication, super.key});
  final UiaRequestState state;
  final Function(String password)? onSubmitAuthentication;

  @override
  State<MatrixUIARequestView> createState() => _MatrixUIARequestViewState();
}

class _MatrixUIARequestViewState extends State<MatrixUIARequestView> {
  TextEditingController passwordFieldController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 200,
      child: buildView(),
    );
  }

  Widget buildView() {
    switch (widget.state) {
      case UiaRequestState.done:
        // TODO: Handle this case.
        break;
      case UiaRequestState.fail:
        // TODO: Handle this case.
        break;
      case UiaRequestState.loading:
        // TODO: Handle this case.
        break;
      case UiaRequestState.waitForUser:
        return userPasswordInput();
    }

    return tiamat.Text(widget.state.toString());
  }

  Widget userPasswordInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextInput(
          placeholder: "Account Password",
          obscureText: true,
          controller: passwordFieldController,
        ),
        Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                  width: 100,
                  height: 40,
                  child: Button(
                    text: "Submit",
                    onTap: () => this
                        .widget
                        .onSubmitAuthentication
                        ?.call(passwordFieldController.text),
                  )),
            ))
      ],
    );
  }
}
