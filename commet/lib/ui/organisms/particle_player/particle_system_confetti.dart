import 'dart:math';
import 'dart:ui';

import 'dart:ui' as ui;
import 'package:commet/client/components/message_effects/message_effect_particles.dart';
import 'package:flutter/material.dart';
import 'package:starfield/starfield.dart';

class MessageEffectConfetti implements MessageEffectParticles {
  @override
  EcsParticleSystem? system;

  @override
  Future<void> init() async {
    var data = await ImmutableBuffer.fromAsset(
        "assets/images/effects/particles/confetti.webp");
    var codec = await ui.instantiateImageCodecFromBuffer(data);
    var sprite = ParticleSprite();

    await sprite.init(
        codec: codec,
        spriteSheet: SpriteSheetInfo(
            frames: 59, frameWidth: 64, frameHeight: 64, framesPerSecond: 50));
    system =
        ParticleSystemConfetti(sprite: sprite, spriteSize: 0.2, gravity: 10);
    system!.setSize(200);
  }

  void reset() {
    init();
  }
}

class ParticleSystemConfetti extends ParticleSystemExplosion {
  static const List<ui.Color> possibleColors = [
    Color.fromARGB(255, 252, 10, 10),
    Color.fromARGB(255, 252, 119, 10),
    Color.fromARGB(255, 252, 196, 10),
    Color.fromARGB(255, 167, 252, 10),
    Color.fromARGB(255, 10, 252, 22),
    Color.fromARGB(255, 10, 252, 220),
    Color.fromARGB(255, 10, 135, 252),
    Color.fromARGB(255, 115, 10, 252),
    Color.fromARGB(255, 252, 10, 252),
  ];

  ParticleSystemConfetti({
    super.sprite,
    super.spriteSize = 1,
    super.gravity = 30,
  });

  @override
  Alignment get alignment => Alignment.bottomCenter;

  @override
  void setDefaultProperties(int index) {
    double angle = lerpDouble(-0.5, 0.5, r.nextDouble())!;
    double x = sin(angle);
    double y = cos(angle);

    setColor(index, possibleColors[index % possibleColors.length].value);

    setVelocityX(index, x * 4000);
    setVelocityY(index, r.nextDouble() * -y * 4000);

    setAngularVelocity(index, (r.nextDouble() - 0.5) * 20);
  }
}
