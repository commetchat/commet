import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/ui/pages/settings/categories/account/security/matrix/cross_signing/cross_signing_view.dart';
import 'package:flutter/widgets.dart';

import 'package:matrix/encryption.dart';

enum MatrixCrossSigningMode {
  standard,
  enableBackup,
  restoreBackup,
  resetCrossSigning,
  crossSigningOnly
}

class MatrixCrossSigningPage extends StatefulWidget {
  const MatrixCrossSigningPage(
      {required this.client,
      this.mode = MatrixCrossSigningMode.standard,
      super.key,
      this.onComplete});
  final MatrixClient client;
  final MatrixCrossSigningMode mode;
  final Function()? onComplete;

  @override
  State<MatrixCrossSigningPage> createState() => MatrixCrossSigningPageState();
}

class MatrixCrossSigningPageState extends State<MatrixCrossSigningPage> {
  BootstrapState state = BootstrapState.loading;
  String? errorMessage;
  Bootstrap? bootstrapper;
  @override
  void initState() {
    var mx = widget.client.getMatrixClient();
    bootstrapper = mx.encryption?.bootstrap(onUpdate: onBootstrapperUdate);
    onBootstrapperUdate(bootstrapper!);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MatrixCrossSigningView(
      state,
      recoveryKey: bootstrapper?.newSsssKey?.recoveryKey,
      errorMessage: errorMessage,
      onSetNewSsss: (passphrase) {
        bootstrapper?.newSsss(passphrase);
      },
      onAskSetupCrossSigning: () {
        bootstrapper?.askSetupCrossSigning(
          setupMasterKey: true,
          setupSelfSigningKey: true,
          setupUserSigningKey: true,
        );
      },
      onAskSetupOnlineBackup: (enable) {
        bootstrapper?.askSetupOnlineKeyBackup(enable);
      },
      useExistingKeys: (use) {
        bootstrapper?.useExistingSsss(use);
      },
      wipeSsss: (wipe) {
        bootstrapper?.wipeSsss(wipe);
        if (!wipe) {
          bootstrapper?.useExistingSsss(true);
          bootstrapper?.openExistingSsss();
        }
      },
      wipeExistingBackup: (wipe) {
        bootstrapper?.wipeOnlineKeyBackup(wipe);
      },
      openExistingSsss: (key) async {
        try {
          await bootstrapper?.newSsssKey!.unlock(keyOrPassphrase: key);
          await bootstrapper?.openExistingSsss();
        } catch (e, s) {
          debugPrint('[Cross Signing] Error opening existing SSSS: $e\n$s');
          setState(() {
            errorMessage = e.toString();
            state = BootstrapState.error;
          });
        }
      },
      ignoreBadSecrets: (ignore) {
        bootstrapper?.ignoreBadSecrets(ignore);
      },
      unlockedSsss: (key) async {
        try {
          if (bootstrapper?.oldSsssKeys != null) {
            for (final oldKey in bootstrapper!.oldSsssKeys!.values) {
              await oldKey.unlock(keyOrPassphrase: key);
            }
          }
          bootstrapper?.unlockedSsss();
        } catch (e, s) {
          debugPrint('[Cross Signing] Error unlocking old SSSS: $e\n$s');
          setState(() {
            errorMessage = e.toString();
            state = BootstrapState.error;
          });
        }
      },
      wipeCrossSigning: (wipe) {
        bootstrapper?.wipeCrossSigning(wipe);
      },
    );
  }

  void onBootstrapperUdate(Bootstrap bootstrapper) async {
    if (bootstrapper.state == BootstrapState.done) {
      widget.onComplete?.call();
    }

    if (widget.mode == MatrixCrossSigningMode.enableBackup ||
        widget.mode == MatrixCrossSigningMode.restoreBackup) {
      switch (bootstrapper.state) {
        case BootstrapState.askUseExistingSsss:
          bootstrapper.useExistingSsss(true);
          break;
        case BootstrapState.askWipeSsss:
          bootstrapper.wipeSsss(false);
          break;
        case BootstrapState.askWipeCrossSigning:
          bootstrapper.wipeCrossSigning(false);
          break;
        case BootstrapState.askWipeOnlineKeyBackup:
          bootstrapper.wipeOnlineKeyBackup(false);
          break;
        default:
          break;
      }
    }

    setState(() {
      state = bootstrapper.state;
    });
  }
}
