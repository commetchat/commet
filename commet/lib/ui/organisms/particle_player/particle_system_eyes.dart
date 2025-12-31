import 'dart:ui';

import 'dart:ui' as ui;
import 'package:commet/client/components/message_effects/message_effect_particles.dart';
import 'package:flutter/material.dart';

import 'package:starfield/starfield.dart';

class MessageEffectEyes implements MessageEffectParticles {
  @override
  EcsParticleSystem? system;

  final int numParticles;

  MessageEffectEyes({this.numParticles = 300});

  @override
  Future<void> init() async {
    var data = await ImmutableBuffer.fromAsset(
        "assets/images/effects/particles/fluent-emoji-eyes.webp");
    var codec = await ui.instantiateImageCodecFromBuffer(data);
    var sprite = ParticleSprite();

    await sprite.init(
        codec: codec,
        spriteSheet: SpriteSheetInfo(
            frames: 49,
            frameWidth: 128,
            frameHeight: 128,
            framesPerSecond: 30));

    system = ParticleSystemEyes(
        sprite: sprite, spriteSize: 0.4, gravity: -10, height: 500);
    system!.setSize(numParticles);
  }

  void reset() {
    init();
  }
}

class ParticleSystemEyes extends ParticleSystemRain {
  @override
  Alignment get alignment => Alignment.bottomLeft;

  ParticleSystemEyes({
    super.sprite,
    super.spriteSize = 1,
    super.gravity = 30,
    super.height = 1000,
  });

  @override
  void processRotations(double delta) {
    return;
  }

  @override
  void setDefaultProperties(int index) {
    double x = r.nextDouble() * currentSize!.width;
    double y = (sprite?.height ?? 10) + r.nextDouble() * height;

    setPositionX(index, x);
    setPositionY(index, y);

    setScale(index, (r.nextDouble() * 0.4).clamp(0.1, 0.4));
  }

  @override
  bool shouldStop() {
    if (currentSize == null) {
      return false;
    }

    var topBound = currentSize!.height;

    if (sprite != null) {
      topBound += sprite!.height.toDouble();
    }

    for (int i = 0; i < numParticles; i++) {
      var h = positions[indexToPosYIndex(i)];
      if (h > -topBound) {
        return false;
      }
    }

    return true;
  }
}
