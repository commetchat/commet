import 'dart:async';
import 'dart:math';

import 'package:commet/client/components/typing_indicators/typing_indicator_component.dart';
import 'package:commet/client/member.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class TypingIndicatorsWidget extends StatefulWidget {
  const TypingIndicatorsWidget({required this.component, super.key});
  final TypingIndicatorComponent component;

  @override
  State<TypingIndicatorsWidget> createState() => _TypingIndicatorsWidgetState();
}

class _TypingIndicatorsWidgetState extends State<TypingIndicatorsWidget> {
  StreamSubscription? sub;

  late List<Member> typingMembers;

  late String currentText = "";

  String typingUsers(int howMany, String user1, String user2, String user3) =>
      Intl.plural(howMany,
          one: "$user1 is typing...",
          two: "$user1 and $user2 are typing...",
          few: "$user1, $user2, and $user3 are typing...",
          other: "Several people are typing...",
          desc: "Text to display which users are currently typing",
          name: "typingUsers",
          args: [howMany, user1, user2, user3]);

  @override
  void initState() {
    sub = widget.component.onTypingUsersUpdated.listen(onTypingUsersUpdated);
    typingMembers = widget.component.typingUsers;
    if (typingMembers.isNotEmpty) {
      currentText = getTypingText();
    }
    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  void onTypingUsersUpdated(void event) {
    setState(() {
      typingMembers = widget.component.typingUsers;
      if (typingMembers.isNotEmpty) {
        currentText = getTypingText();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 23,
        child: ClipRect(
          child: AnimatedSlide(
              duration: Durations.medium3,
              curve: Curves.easeInOutExpo,
              offset: typingMembers.isEmpty ? const Offset(0, 1) : Offset.zero,
              child: Row(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  child: TypingIndicatorAnimation(
                    playing: typingMembers.isNotEmpty,
                  ),
                ),
                tiamat.Text.labelLow(currentText)
              ])),
        ));
  }

  String getTypingText() {
    String user1 = typingMembers[0].displayName;
    String user2 =
        typingMembers.length >= 2 ? typingMembers[1].displayName : "";
    String user3 =
        typingMembers.length >= 3 ? typingMembers[2].displayName : "";
    return typingUsers(typingMembers.length, user1, user2, user3);
  }
}

class SingleTypingIndicatorBlob extends StatefulWidget {
  const SingleTypingIndicatorBlob(
      {this.color, this.border, super.key, this.playing = true});
  final Color? color;
  final BoxBorder? border;
  final bool playing;
  @override
  State<SingleTypingIndicatorBlob> createState() =>
      SingleTypingIndicatorBlobState();
}

class SingleTypingIndicatorBlobState extends State<SingleTypingIndicatorBlob>
    with TickerProviderStateMixin {
  late AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 200), vsync: this, value: 1);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SingleTypingIndicatorBlob oldWidget) {
    if (widget.playing) {
      controller.reset();
      controller.forward();
    } else {
      controller.value = 0;
      controller.stop();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          var alpha = 1.0;
          alpha -= sin(controller.value * 3.1415926) * 0.4;

          var translation = sin(controller.value * 3.1415926);

          return SizedBox(
            height: 6,
            width: 6,
            child: Align(
              alignment: Alignment.center,
              heightFactor: controller.value,
              child: Transform(
                transform: Matrix4.translationValues(0, translation * 4, 0),
                child: Align(
                  heightFactor: alpha,
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: widget.border,
                        color: widget.color ??
                            Theme.of(context).colorScheme.secondary),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TypingIndicatorAnimation extends StatefulWidget {
  const TypingIndicatorAnimation({super.key, this.playing = true});
  final bool playing;

  @override
  State<TypingIndicatorAnimation> createState() =>
      _TypingIndicatorAnimationState();
}

class _TypingIndicatorAnimationState extends State<TypingIndicatorAnimation> {
  late List<GlobalKey> blobKeys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
  ];

  Timer? timer;
  int prevIndex = 0;
  bool playing = false;

  @override
  void initState() {
    super.initState();
    playing = widget.playing;
    if (playing) {
      startTimer();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TypingIndicatorAnimation oldWidget) {
    if (widget.playing == false) {
      timer?.cancel();
      timer = null;
    } else {
      startTimer();
    }

    setState(() {
      playing = widget.playing;
    });

    super.didUpdateWidget(oldWidget);
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 250), onTimer);
  }

  void onTimer(Timer timer) {
    var r = Random().nextInt(3);

    if (r == prevIndex) {
      r += 1;
      r = r % blobKeys.length;
    }

    prevIndex = r;

    var key = blobKeys[r];

    if (key.currentState == null) {
      return;
    }

    var state = key.currentState! as SingleTypingIndicatorBlobState;
    state.controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SingleTypingIndicatorBlob(
        key: blobKeys[0],
        playing: playing,
      ),
      SingleTypingIndicatorBlob(
        key: blobKeys[1],
        playing: playing,
      ),
      SingleTypingIndicatorBlob(
        key: blobKeys[2],
        playing: playing,
      ),
    ]);
  }
}
