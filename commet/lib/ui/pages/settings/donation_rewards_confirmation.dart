import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/donation_awards/donation_awards_component.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/organisms/particle_player/particle_system_confetti.dart';
import 'package:flutter/material.dart';
import 'package:starfield/particle_system/ecs_particle_system.dart';
import 'package:starfield/renderer/particle_system_renderer.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class DonationRewardsConfirmation extends StatefulWidget {
  const DonationRewardsConfirmation(
      {required this.client,
      required this.identifier,
      required this.since,
      super.key});
  final Client client;
  final SecretClientIdentifier identifier;
  final DateTime since;

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
    loop();
    super.initState();
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
      // since: widget.since,
    );
    if (result != null) {
      var effect = MessageEffectConfetti();
      print("initializing confetti");
      await effect.init();
      print("Done");
      print(effect.system);
      setState(() {
        receivedAwards = result;
        particles = effect.system;
      });
    }
  }

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
                  "Confirming donation",
                  style: TextTheme.of(context).headlineSmall,
                ),
                tiamat.Text.labelLow("Follow the instructions in your browser"),
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
                  if (receivedAwards != null)
                    Container(
                      decoration: BoxDecoration(
                          color: ColorScheme.of(context).surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                            spacing: 10,
                            children: receivedAwards!
                                .map((i) => buildAward(i))
                                .toList()),
                      ),
                    ),
                  if (receivedAwards != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: tiamat.Text.labelLow(
                          "Thank you for your generous donation!"),
                    )
                ],
              ),
              Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (receivedAwards != null)
                    IgnorePointer(
                      ignoring: acceptLoading,
                      child: tiamat.Button(
                          text: "Accept!",
                          isLoading: acceptLoading,
                          onTap: () async {
                            setState(() {
                              acceptLoading = true;
                            });

                            await widget.client
                                .getComponent<DonationAwardsComponent>()
                                ?.acceptAwards(receivedAwards!
                                    .map((i) => i.data)
                                    .toList());

                            Navigator.of(context).pop();
                          }),
                    ),
                  tiamat.Button.secondary(
                    text: "Dismiss",
                    onTap: () => Navigator.of(context).pop(),
                  )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAward(DonationAward i) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 12,
      children: [
        SizedBox(height: 64, width: 64, child: Image(image: i.image)),
        tiamat.Text.largeTitle(i.title)
      ],
    );
  }
}
