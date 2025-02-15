import 'package:starfield/starfield.dart';

abstract class MessageEffectParticles {
  EcsParticleSystem? system;

  MessageEffectParticles(this.system);

  Future<void> init();
}
