import 'package:commet/ui/pages/matrix/authentication/matrix_uia_request_view.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:commet/utils/links/link_utils.dart';
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
  late Set<String> steps;

  @override
  void initState() {
    state = widget.request.state;

    originalOnUpdate = widget.request.onUpdate;
    widget.request.onUpdate = onUpdate;
    steps = widget.request.nextStages;

    super.initState();
  }

  void onUpdate(UiaRequestState state) {
    setState(() {
      this.state = state;
      this.steps = widget.request.nextStages;
    });

    originalOnUpdate?.call(state);
  }

  @override
  Widget build(BuildContext context) {
    return MatrixUIARequestView(
      state,
      nextSteps: steps,
      onSubmitAuthentication: submitAuthentication,
      onSubmitSso: submitSso,
      onSuccess: () => Navigator.of(context).pop(),
      onFail: () => Navigator.of(context).pop(),
    );
  }

  void submitAuthentication(String password) {
    ErrorUtils.tryRun(context, () async {
      await widget.request.completeStage(AuthenticationPassword(
          password: password,
          identifier: AuthenticationUserIdentifier(
              user: widget.client.matrixClient.userID!)));
    });
  }

  submitSso() {
    // https://spec.matrix.org/v1.15/client-server-api/#client-behaviour-21
    var hs = widget.client.matrixClient.homeserver!;
    var url = hs.replace(
        path: "/_matrix/client/v3/auth/m.login.sso/fallback/web",
        queryParameters: {"session": widget.request.session});

    LinkUtils.open(url,
        bypassConfirmation: true,
        filterTrackingParameters: false,
        context: context);
    Navigator.of(context).pop();
  }
}
