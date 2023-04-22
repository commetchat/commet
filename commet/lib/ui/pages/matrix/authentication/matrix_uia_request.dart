import 'package:commet/ui/pages/matrix/authentication/matrix_uia_request_view.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

import '../../../../client/matrix/matrix_client.dart';

class MatrixUIARequest extends StatefulWidget {
  const MatrixUIARequest(this.request, this.client, {super.key});
  final UiaRequest request;
  final MatrixClient client;
  @override
  State<MatrixUIARequest> createState() => _MatrixUIARequestState();
}

class _MatrixUIARequestState extends State<MatrixUIARequest> {
  void Function(UiaRequestState)? originalOnUpdate;
  late UiaRequestState state;

  @override
  void initState() {
    state = widget.request.state;

    originalOnUpdate = widget.request.onUpdate;
    widget.request.onUpdate = onUpdate;

    super.initState();
  }

  void onUpdate(UiaRequestState state) {
    setState(() {
      this.state = state;
    });

    originalOnUpdate?.call(state);
  }

  @override
  Widget build(BuildContext context) {
    return MatrixUIARequestView(
      state,
      onSubmitAuthentication: submitAuthentication,
      onSuccess: () => Navigator.of(context).pop(),
      onFail: () => Navigator.of(context).pop(),
    );
  }

  void submitAuthentication(String password) {
    var mx = widget.client.getMatrixClient();
    print(mx.userID);

    widget.request.completeStage(
        AuthenticationPassword(password: password, identifier: AuthenticationUserIdentifier(user: "alice")));
  }
}
