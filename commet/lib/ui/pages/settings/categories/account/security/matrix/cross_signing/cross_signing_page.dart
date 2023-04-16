import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/ui/pages/settings/categories/account/security/matrix/cross_signing/cross_signing_view.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:matrix/encryption.dart';

class MatrixCrossSigningPage extends StatefulWidget {
  const MatrixCrossSigningPage({required this.client, super.key});
  final MatrixClient client;
  @override
  State<MatrixCrossSigningPage> createState() => MatrixCrossSigningPageState();
}

class MatrixCrossSigningPageState extends State<MatrixCrossSigningPage> {
  BootstrapState state = BootstrapState.loading;
  Bootstrap? bootstrapper;
  @override
  void initState() {
    var mx = widget.client.getMatrixClient();
    bootstrapper = mx.encryption?.bootstrap(onUpdate: onBootstrapperUdate);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MatrixCrossSigningView(
      state,
      recoveryKey: bootstrapper?.newSsssKey?.recoveryKey,
      onSetNewSsss: (passphrase) {
        bootstrapper?.newSsss(passphrase);
      },
      onAskSetupCrossSigning: () {
        bootstrapper?.askSetupCrossSigning(
          setupMasterKey: true,
        );
      },
    );
  }

  void onBootstrapperUdate(Bootstrap bootstrapper) {
    setState(() {
      state = bootstrapper.state;
    });
  }
}
