import 'dart:ui';

import 'dart:ui' as ui;
import 'package:commet/client/components/message_effects/message_effect_particles.dart';
import 'package:flutter/material.dart';
import 'package:starfield/starfield.dart';

class MessageEffectSpaceInvaders implements MessageEffectParticles {
  @override
  EcsParticleSystem? system;

  int factor = 1;

  @override
  Future<void> init() async {
    var data = await ImmutableBuffer.fromAsset(
        "assets/images/effects/particles/fluent-emoji-alien-monster.png");
    var codec = await ui.instantiateImageCodecFromBuffer(data);
    var sprite = ParticleSprite();

    await sprite.init(
      codec: codec,
    );

    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

    // Dimensions in logical pixels (dp)
    Size size = view.physicalSize / view.devicePixelRatio;
    double width = size.width;

    int rows = (width / 200).toInt();

    int columns = 5;

    system = ParticleSystemSpaceInvaders(
        sprite: sprite, spriteSize: 0.2, gravity: 5, factor: rows);

    int numParticles = rows * columns;

    system!.setSize(numParticles);
  }

  void reset() {
    init();
  }
}

class ParticleSystemSpaceInvaders extends ParticleSystemRain {
  ParticleSystemSpaceInvaders({
    super.sprite,
    super.spriteSize = 1,
    super.gravity = 30,
    super.height = 1000,
    this.factor = 1,
  });

  @override
  Alignment get alignment => Alignment.topLeft;

  int factor;

  @override
  void setDefaultProperties(int index) {
    super.setDefaultProperties(index);

    int x = index % factor;
    int y = index ~/ factor;
    setPositionX(index, 40 + (x / factor) * currentSize!.width);
    setPositionY(index, -y * 90);
  }

  @override
  void processVelocities(double delta) {
    for (int i = 0; i < numParticles; i++) {
      int iy = indexToPosYIndex(i);
      var vy = velocities[iy];

      vy += gravity;
      vy *= 0.98;

      velocities[iy] = vy;
    }
  }

  @override
  void setDefaultSpriteProperties(int index) {
    setColor(index, 0xFFFFFFFF);
    setScale(index, spriteSize);

    double? rectW = sprite?.width.toDouble();
    double? rectH = sprite?.height.toDouble();

    rects[index * 4 + 0] = 0;
    rects[index * 4 + 1] = 0.0;
    rects[index * 4 + 2] = rectW!;
    rects[index * 4 + 3] = rectH!;
  }

  @override
  void processRotations(double delta) {
    return;
  }
}
