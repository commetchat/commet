import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/donation_awards/donation_awards_component.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/particle_player/particle_system_confetti.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:starfield/particle_system/ecs_particle_system.dart';
import 'package:starfield/renderer/particle_system_renderer.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class DonationRewardsConfirmation extends StatefulWidget {
  const DonationRewardsConfirmation(
      {required this.client,
      required this.identifier,
      required this.since,
      required this.didOpenDonationWindow,
      super.key});
  final Client client;
  final SecretClientIdentifier identifier;
  final DateTime? since;
  final bool didOpenDonationWindow;

  @override
  State<DonationRewardsConfirmation> createState() =>
      _DonationRewardsConfirmationState();
}

class _DonationRewardsConfirmationState
    extends State<DonationRewardsConfirmation> with WidgetsBindingObserver {
  late DonationAwardsClient awards;
  List<DonationAward>? receivedAwards;
  EcsParticleSystem? particles;

  bool acceptLoading = false;

  @override
  void initState() {
    awards =
        DonationAwardsClient(BuildConfig.donationRewardsApiHost, widget.client);

    WidgetsBinding.instance.addObserver(this);

    if (widget.since != null) {
      loop();
    } else {
      awards.getAwards(widget.identifier).then((result) {
        setState(() {
          if (result == null) {
            receivedAwards = [];
          } else {
            receivedAwards = result;
          }

          if (receivedAwards?.isNotEmpty == true) {
            doConfetti();
          }
        });
      });
    }

    super.initState();
  }

  void doConfetti() async {
    print("initializing confetti");
    var effect = MessageEffectConfetti();

    await effect.init();

    setState(() {
      particles = effect.system;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void loop() async {
    while (receivedAwards == null && context.mounted) {
      try {
        await checkConfirmation();
      } catch (e, s) {
        Log.onError(e, s);
      }

      await Future.delayed(Duration(seconds: 10));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    setState(() {});
  }

  Future<void> checkConfirmation() async {
    var result = await awards.getAwards(
      widget.identifier,
      since: widget.since,
    );
    if (result != null) {
      if (result.isNotEmpty) {
        doConfetti();

        preferences.clearRunningDonationCheckFlow();
      }
      setState(() {
        receivedAwards = result;
      });
    }
  }

  String get titleConfirmingDonation => Intl.message("Confirming Donation",
      name: "titleConfirmingDonation",
      desc:
          "Title for the popup shown while waiting for the user to finish the donation flow, which checks for completion of the donation");

  String get labelDonationInstructions => Intl.message(
      "Follow the instructions in your browser. Please be patient, it may take a minute or two for your awards to appear once your donation has been received.",
      name: "labelDonationInstructions",
      desc:
          "Explains to the user to follow the donation instructions shown in the opened web page. Also asks for patience if the confirmation is taking a while to complete after donating");

  String get labelDonationConfirmationSucceeded => Intl.message(
      "Thank you for your generous donation!",
      name: "labelDonationConfirmationSucceeded",
      desc:
          "Text that is shown when the donation flow was successful, and the donation has been confirmed");

  String get labelDonationConfirmationFailed => Intl.message(
      "Could not find any donations :( Please consider donating to support development of Commet!",
      name: "labelDonationConfirmationFailed",
      desc:
          "Text that is shown when the donation flow was failed, and the no donation was found");

  String get labelConfirmCancelDonationConfirmation => Intl.message(
      "Are you sure you want to dismiss without accepting any award?",
      name: "labelConfirmCancelDonationConfirmation",
      desc:
          "Text that is shown when the user attempts to cancel the donation confirmation flow before the confirmation has finished");

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      width: 800,
      child: Stack(
        children: [
          if (particles != null &&
              WidgetsBinding.instance.lifecycleState ==
                  AppLifecycleState.resumed)
            SizedBox(
                width: 800,
                height: 500,
                child: ParticleSystemRenderer(system: particles!)),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  titleConfirmingDonation,
                  style: TextTheme.of(context).headlineSmall,
                ),
                if (widget.didOpenDonationWindow)
                  tiamat.Text.labelLow(labelDonationInstructions),
              ]),
              Column(
                children: [
                  if (receivedAwards == null)
                    SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (receivedAwards?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                          spacing: 10,
                          children: receivedAwards!
                              .map((i) => buildAward(i))
                              .toList()),
                    ),
                  if (receivedAwards?.isEmpty == true)
                    tiamat.Text.labelLow(labelDonationConfirmationFailed),
                  if (receivedAwards?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: tiamat.Text.labelLow(
                          labelDonationConfirmationSucceeded),
                    )
                ],
              ),
              Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (receivedAwards?.isNotEmpty == true)
                    IgnorePointer(
                      ignoring: acceptLoading,
                      child: tiamat.Button(
                          text: CommonStrings.promptAccept,
                          isLoading: acceptLoading,
                          onTap: () async {
                            setState(() {
                              acceptLoading = true;
                            });

                            preferences.clearRunningDonationCheckFlow();

                            await widget.client
                                .getComponent<DonationAwardsComponent>()
                                ?.acceptAwards(receivedAwards!
                                    .map((i) => i.data)
                                    .toList());

                            Navigator.of(context).pop();
                          }),
                    ),
                  tiamat.Button.secondary(
                      text: CommonStrings.promptDismiss,
                      onTap: () async {
                        if (receivedAwards?.isEmpty == true ||
                            await AdaptiveDialog.confirmation(context,
                                    prompt:
                                        labelConfirmCancelDonationConfirmation) ==
                                true) {
                          preferences.clearRunningDonationCheckFlow();
                          Navigator.of(context).pop();
                        }
                      })
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAward(DonationAward i) {
    return Container(
      decoration: BoxDecoration(
          color: ColorScheme.of(context).surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            SizedBox(height: 64, width: 64, child: Image(image: i.image)),
            tiamat.Text.largeTitle(i.title)
          ],
        ),
      ),
    );
  }
}
