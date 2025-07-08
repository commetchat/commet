import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/message_effects/message_effect_component.dart';
import 'package:commet/client/components/message_effects/message_effect_particles.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/ui/organisms/particle_player/particle_system_confetti.dart';
import 'package:commet/ui/organisms/particle_player/particle_system_eyes.dart';
import 'package:commet/ui/organisms/particle_player/particle_system_hug.dart';
import 'package:commet/ui/organisms/particle_player/particle_system_snow.dart';
import 'package:commet/ui/organisms/particle_player/particle_system_space_invaders.dart';
import 'package:commet/utils/event_bus.dart';

import 'package:matrix/matrix.dart' as matrix;

class MatrixMessageEffectsComponent
    implements MessageEffectComponent<MatrixClient> {
  @override
  final MatrixClient client;

  static const effectTypeSnowfall = "io.element.effect.snowfall";
  static const effectTypeConfetti = "nic.custom.confetti";
  static const effectTypeSpaceInvaders = "io.element.effects.space_invaders";
  static const effectTypeCuteEvent = "im.fluffychat.cute_event";
  static const effectTypeGoogly = "googly_eyes";
  static const effectTypeHug = "hug";

  MatrixMessageEffectsComponent(this.client) {
    var mx = client.getMatrixClient();

    mx.addCommand(
        "snowfall",
        (args, _) =>
            sendWithMsgType(args, msgType: effectTypeSnowfall, fallback: "❄️"));

    mx.addCommand(
        "confetti",
        (args, _) =>
            sendWithMsgType(args, msgType: effectTypeConfetti, fallback: "🎉"));

    mx.addCommand(
        "spaceinvaders",
        (args, _) => sendWithMsgType(args,
            msgType: effectTypeSpaceInvaders, fallback: "👾"));
  }

  static const Set<String> knownEffectTypes = {
    effectTypeSnowfall,
    effectTypeConfetti,
    effectTypeSpaceInvaders,
    effectTypeCuteEvent,
  };

  String? getEffectType(TimelineEvent event) {
    if (!hasEffect(event)) {
      return null;
    }

    var mxevent = (event as MatrixTimelineEvent).event;
    var type = mxevent.content["msgtype"] as String;

    if (type == "im.fluffychat.cute_event") {
      type = mxevent.content['cute_type'] as String;
    }

    return type;
  }

  @override
  void doEffect(TimelineEvent event) async {
    if (!hasEffect(event)) {
      return;
    }
    final type = getEffectType(event);
    if (type == null) {
      return;
    }

    final effect = createEffect(type);

    if (effect == null) {
      return;
    }

    await effect.init();
    EventBus.doMessageEffect.add(effect);
  }

  MessageEffectParticles? createEffect(String type) {
    switch (type) {
      case effectTypeConfetti:
        return MessageEffectConfetti();
      case effectTypeSnowfall:
        return MessageEffectSnow();
      case effectTypeSpaceInvaders:
        return MessageEffectSpaceInvaders();
      case effectTypeGoogly:
        return MessageEffectEyes();
      case effectTypeHug:
        return MessageEffectHug();
    }

    return null;
  }

  FutureOr<String?> sendWithMsgType(matrix.CommandArgs args,
      {required String msgType, required String fallback}) async {
    args.room?.sendEvent({
      "msgtype": msgType,
      "body": args.msg.trim().isEmpty ? fallback : args.msg,
    });

    return null;
  }

  @override
  bool hasEffect(TimelineEvent<Client> event) {
    if (event is! MatrixTimelineEvent) {
      return false;
    }

    final mxEvent = event.event;
    if (mxEvent.type != matrix.EventTypes.Message) {
      return false;
    }

    final type = mxEvent.content["msgtype"];
    if (type == null || type is! String) {
      return false;
    }

    return knownEffectTypes.contains(type);
  }
}
