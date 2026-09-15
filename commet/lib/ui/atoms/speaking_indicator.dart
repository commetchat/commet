import 'package:flutter/material.dart';

/// Discord style speaking indicator: a solid green ring around the avatar,
/// plus waves that keep rippling outwards while the user is talking.
///
/// Expects [child] to be a `tiamat.Avatar` of the given [radius], whose
/// corners are rounded with `radius / 1.25`.
class SpeakingIndicator extends StatefulWidget {
  const SpeakingIndicator({
    required this.speaking,
    required this.radius,
    required this.child,
    super.key,
  });

  static const Color color = Color(0xFF23A55A);

  final bool speaking;
  final double radius;
  final Widget child;

  @override
  State<SpeakingIndicator> createState() => _SpeakingIndicatorState();
}

class _SpeakingIndicatorState extends State<SpeakingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    reverseDuration: const Duration(milliseconds: 300),
  );

  late final AnimationController waves = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    fade.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) waves.stop();
    });
    if (widget.speaking) start();
  }

  @override
  void didUpdateWidget(SpeakingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.speaking == oldWidget.speaking) return;
    if (widget.speaking) {
      start();
    } else {
      fade.reverse();
    }
  }

  void start() {
    fade.forward();
    if (!waves.isAnimating) waves.repeat();
  }

  @override
  void dispose() {
    fade.dispose();
    waves.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _SpeakingPainter(
        fade: fade,
        waves: waves,
        radius: widget.radius,
      ),
      child: widget.child,
    );
  }
}

class _SpeakingPainter extends CustomPainter {
  _SpeakingPainter({
    required this.fade,
    required this.waves,
    required this.radius,
  }) : super(repaint: Listenable.merge([fade, waves]));

  final Animation<double> fade;
  final Animation<double> waves;
  final double radius;

  static const double ringGap = 3;
  static const double ringWidth = 3;
  static const double waveTravel = 20;
  static const int waveCount = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final strength = Curves.easeOut.transform(fade.value);
    if (strength == 0) return;

    final avatar = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(radius / 1.25));

    final ringOffset = ringGap + ringWidth / 2;

    for (var i = 0; i < waveCount; i++) {
      final t = (waves.value + i / waveCount) % 1.0;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth * (1 - t) + 1
        ..color =
            SpeakingIndicator.color.withValues(alpha: 0.7 * (1 - t) * strength);
      canvas.drawRRect(avatar.inflate(ringOffset + t * waveTravel), paint);
    }

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..color = SpeakingIndicator.color.withValues(alpha: strength);
    canvas.drawRRect(avatar.inflate(ringOffset), ring);
  }

  @override
  bool shouldRepaint(_SpeakingPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.fade != fade ||
      oldDelegate.waves != waves;
}
