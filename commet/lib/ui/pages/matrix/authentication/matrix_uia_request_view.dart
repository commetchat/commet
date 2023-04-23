import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as material;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@WidgetbookUseCase(name: 'Wait for user', type: MatrixUIARequestView)
@Deprecated("widgetbook")
Widget wbUIARequestView(BuildContext context) {
  return const material.Scaffold(
    body: PopupDialog(
      title: "Authentication Request",
      content: MatrixUIARequestView(UiaRequestState.waitForUser),
    ),
  );
}

@WidgetbookUseCase(name: 'Loading', type: MatrixUIARequestView)
@Deprecated("widgetbook")
Widget wbUIARequestViewLoading(BuildContext context) {
  return const material.Scaffold(
    body: PopupDialog(
      title: "Authentication Request",
      content: MatrixUIARequestView(UiaRequestState.loading),
    ),
  );
}

@WidgetbookUseCase(name: 'Done', type: MatrixUIARequestView)
@Deprecated("widgetbook")
Widget wbUIARequestViewDone(BuildContext context) {
  return const material.Scaffold(
    body: PopupDialog(
      title: "Authentication Request",
      content: MatrixUIARequestView(UiaRequestState.done),
    ),
  );
}

@WidgetbookUseCase(name: 'Fail', type: MatrixUIARequestView)
@Deprecated("widgetbook")
Widget wbUIARequestViewError(BuildContext context) {
  return const material.Scaffold(
    body: PopupDialog(
      title: "Authentication Request",
      content: MatrixUIARequestView(UiaRequestState.fail),
    ),
  );
}

class MatrixUIARequestView extends StatefulWidget {
  const MatrixUIARequestView(this.state,
      {this.onSubmitAuthentication, super.key, this.onFail, this.onSuccess});
  final UiaRequestState state;
  final Function(String password)? onSubmitAuthentication;
  final Function()? onSuccess;
  final Function()? onFail;

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
        return done(context);
      case UiaRequestState.fail:
        return fail(context);
      case UiaRequestState.loading:
        return loading();
      case UiaRequestState.waitForUser:
        return userPasswordInput();
    }
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
                    onTap: () => widget.onSubmitAuthentication
                        ?.call(passwordFieldController.text),
                  )),
            ))
      ],
    );
  }

  Widget loading() {
    return const Center(
      child: material.CircularProgressIndicator(),
    );
  }

  Widget done(BuildContext context) {
    Navigator.pop(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                material.Icons.verified_user_rounded,
                color: material.Colors.green.shade400,
                size: 40,
              ),
            ),
            const tiamat.Text.largeTitle("Success!")
          ],
        ),
        SizedBox(
          height: 40,
          width: 200,
          child: tiamat.Button.success(
            text: "Continue",
            onTap: () => widget.onSuccess?.call(),
          ),
        )
      ],
    );
  }

  Widget fail(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                material.Icons.error_outline,
                color: material.Theme.of(context).colorScheme.error,
                size: 40,
              ),
            ),
            const tiamat.Text.largeTitle("Login failed...")
          ],
        ),
        SizedBox(
          height: 40,
          width: 200,
          child: tiamat.Button.danger(
            text: "Continue",
            onTap: () => widget.onFail?.call(),
          ),
        )
      ],
    );
  }
}
