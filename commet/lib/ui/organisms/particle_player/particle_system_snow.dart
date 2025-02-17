import 'dart:ui';

import 'dart:ui' as ui;
import 'package:commet/client/components/message_effects/message_effect_particles.dart';
import 'package:starfield/starfield.dart';

class MessageEffectSnow implements MessageEffectParticles {
  @override
  EcsParticleSystem? system;

  @override
  Future<void> init() async {
    var data = await ImmutableBuffer.fromAsset(
        "assets/images/effects/particles/fluent-emoji-snowflake.webp");
    var codec = await ui.instantiateImageCodecFromBuffer(data);
    var sprite = ParticleSprite();

    await sprite.init(
        codec: codec,
        spriteSheet: SpriteSheetInfo(
            frames: 72,
            frameWidth: 128,
            frameHeight: 128,
            framesPerSecond: 30));

    system = ParticleSystemSnow(
        sprite: sprite, spriteSize: 0.3, gravity: 10, height: 500);
    system!.setSize(500);
  }

  void reset() {
    init();
  }
}

class ParticleSystemSnow extends ParticleSystemRain {
  ParticleSystemSnow({
    super.sprite,
    super.spriteSize = 1,
    super.gravity = 30,
    super.height = 1000,
  });

  @override
  void processRotations(double delta) {
    return;
  }
}
