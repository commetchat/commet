import 'package:commet/ui/pages/matrix/authentication/matrix_uia_request_view.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
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
  @override
  Widget build(BuildContext context) {
    return MatrixUIARequestView(
      widget.request.state,
      onSubmitAuthentication: submitAuthentication,
    );
  }

  void submitAuthentication(String password) {
    var mx = widget.client.getMatrixClient();
    print(mx.userID);

    widget.request.completeStage(AuthenticationPassword(
        password: password,
        identifier: AuthenticationUserIdentifier(user: "alice")));
  }
}
