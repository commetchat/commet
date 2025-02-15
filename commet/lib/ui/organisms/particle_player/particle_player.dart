import 'dart:async';

import 'package:commet/client/components/message_effects/message_effect_particles.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:starfield/starfield.dart';

class ParticlePlayer extends StatefulWidget {
  const ParticlePlayer({super.key});

  @override
  State<ParticlePlayer> createState() => _ParticlePlayerState();
}

class _ParticlePlayerState extends State<ParticlePlayer> {
  Timer? timer;
  MessageEffectParticles? currentEffect;
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    sub = EventBus.doMessageEffect.stream.listen(onDoMessageEffect);
  }

  void onDoMessageEffect(MessageEffectParticles effect) {
    setState(() {
      currentEffect = effect;
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 1), onTimer);
    });
  }

  void onTimer(Timer timer) {
    final shouldStop = currentEffect?.system?.shouldStop();
    Log.d("Should stop particle effect: $shouldStop");
    if (shouldStop == true) {
      Log.d("Stopping message effect");
      setState(() {
        currentEffect = null;
      });
      timer.cancel();
      this.timer = null;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentEffect?.system != null) {
      return IgnorePointer(
          child: ParticleSystemRenderer(system: currentEffect!.system!));
    } else {
      return Container();
    }
  }
}
