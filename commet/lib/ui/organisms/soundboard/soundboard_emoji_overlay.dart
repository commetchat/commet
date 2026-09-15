// Emoji burst overlay for soundboard triggers.
//
// Placed over the sender's avatar (Stack). Entrance: scale 0.4->1.15 with
// easeOutBack + fade in; hold; exit: fade+scale down. Duration comes from
// the engine's ActiveSound.overlayMs (real sound duration clamped to
// 1200..3500ms). Never replaces the avatar — pure overlay, IgnorePointer.
import 'package:flutter/material.dart';

class SoundboardEmojiOverlay extends StatefulWidget {
  final String emoji;
  final int durationMs;
  final VoidCallback? onDone;

  const SoundboardEmojiOverlay({
    super.key,
    required this.emoji,
    required this.durationMs,
    this.onDone,
  });

  @override
  State<SoundboardEmojiOverlay> createState() =>
      _SoundboardEmojiOverlayState();
}

class _SoundboardEmojiOverlayState extends State<SoundboardEmojiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    // Entrance ~25%, hold ~50%, exit ~25%.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.6)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_controller);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_controller);
    _controller.forward().whenComplete(() => widget.onDone?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 34),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
