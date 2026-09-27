// The update control in settings: what is running, a button to look for
// something newer, and, once one is unpacked and waiting, a restart.
//
// Always here, whatever the "check for updates" preference says: that
// preference only governs the check that runs by itself at startup, and
// somebody who turned it off should still be able to ask.
import 'package:commet/config/build_config.dart';
import 'package:commet/utils/links/link_utils.dart';
import 'package:commet/utils/update_checker.dart';
import 'package:commet/utils/updater/self_updater.dart';
import 'package:commet/utils/window_management.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class UpdateButton extends StatefulWidget {
  const UpdateButton({super.key});

  @override
  State<UpdateButton> createState() => _UpdateButtonState();
}

class _UpdateButtonState extends State<UpdateButton> {
  SelfUpdater get updater => SelfUpdater.instance;

  Future<void> _restart() async {
    if (await updater.installAndRestart()) {
      await WindowManagement.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UpdateProgress>(
      valueListenable: updater.progress,
      builder: (context, progress, _) {
        final release = progress.release;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const tiamat.Text.label("Version"),
                      tiamat.Text.labelLow(_status(progress)),
                    ],
                  ),
                ),
                if (progress.stage == UpdateStage.ready)
                  tiamat.Button.success(
                    text: "Restart to update",
                    onTap: _restart,
                  )
                else if (progress.stage == UpdateStage.available &&
                    release != null)
                  tiamat.Button(
                    text: "Open release page",
                    onTap: () => LinkUtils.open(
                        Uri.parse(UpdateChecker.releasesPageUrl),
                        context: context),
                  )
                else
                  tiamat.Button(
                    text: "Check for updates",
                    onTap: progress.busy ? null : updater.checkAndPrepare,
                  ),
              ],
            ),
            if (progress.fraction != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(value: progress.fraction),
              ),
          ],
        );
      },
    );
  }

  String _status(UpdateProgress progress) {
    final version = BuildConfig.VERSION_TAG;
    final tag = progress.release?.tag;
    return switch (progress.stage) {
      UpdateStage.checking => "Looking for a newer version…",
      UpdateStage.downloading => progress.fraction == null
          ? "Downloading $tag…"
          : "Downloading $tag… ${(progress.fraction! * 100).round()}%",
      UpdateStage.verifying => "Checking the download…",
      UpdateStage.unpacking => "Unpacking $tag…",
      UpdateStage.ready => progress.message ??
          "$tag is ready. It goes in when roscord restarts.",
      UpdateStage.available => progress.message ?? "$tag is available.",
      UpdateStage.upToDate => progress.message ?? "$version is the latest.",
      UpdateStage.failed => progress.message ?? "The update failed.",
      UpdateStage.idle => version,
    };
  }
}
