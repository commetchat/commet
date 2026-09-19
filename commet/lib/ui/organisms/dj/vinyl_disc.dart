// A vinyl record, drawn: the DJ's badge next to their name, and the record
// behind the sleeve in the booth. Spins at 33⅓ rpm while music plays and
// eases to a stop when it doesn't, like a turntable.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class VinylDisc extends StatefulWidget {
  const VinylDisc({
    super.key,
    this.size = 18,
    this.spinning = true,
    this.labelColor,
    this.label,
  });

  final double size;
  final bool spinning;

  /// Colour of the paper label in the middle; the theme's primary if null.
  final Color? labelColor;

  /// Art on the label (the song's cover), clipped to it.
  final ImageProvider? label;

  @override
  State<VinylDisc> createState() => _VinylDiscState();
}

class _VinylDiscState extends State<VinylDisc>
    with SingleTickerProviderStateMixin {
  // 33⅓ rpm: one turn in 1.8 s.
  static const _turn = Duration(milliseconds: 1800);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _turn);

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _controller.repeat();
  }

  @override
  void didUpdateWidget(VinylDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinning == oldWidget.spinning) return;
    if (widget.spinning) {
      _controller.repeat();
    } else {
      // Coast to a stop over about a quarter turn instead of freezing.
      final velocity = 1 / (_turn.inMilliseconds / 1000);
      _controller.animateWith(FrictionSimulation(0.05, _controller.value,
          velocity, constantDeceleration: velocity * 3)).whenCompleteOrCancel(
          () {
        if (mounted && !widget.spinning) _controller.stop();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.labelColor ?? Theme.of(context).colorScheme.primary;
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.rotate(
            angle: _controller.value * 2 * pi,
            child: child,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _VinylPainter(label)),
              if (widget.label != null)
                Center(
                  child: ClipOval(
                    child: SizedBox.square(
                      dimension: widget.size * _VinylPainter.labelFraction,
                      child: Image(
                        image: widget.label!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              if (widget.label != null)
                Center(
                  child: Container(
                    width: max(1.5, widget.size * 0.04),
                    height: max(1.5, widget.size * 0.04),
                    decoration: const BoxDecoration(
                        color: Colors.black, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VinylPainter extends CustomPainter {
  final Color label;

  static const labelFraction = 0.38;

  _VinylPainter(this.label);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF141416));

    // Grooves: faint rings, fewer on a small badge so they don't turn grey.
    final grooves = r < 14 ? 2 : (r < 40 ? 5 : 12);
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.5, r * 0.012)
      ..color = Colors.white.withValues(alpha: 0.07);
    // Between the label (labelFraction of the radius) and the rim.
    const inner = labelFraction + 0.05;
    for (var i = 0; i < grooves; i++) {
      final t = (i + 1) / (grooves + 1);
      canvas.drawCircle(c, r * (inner + t * (0.94 - inner)), groove);
    }

    // A light sheen that turns with the record, so the spin shows.
    final sheen = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.08, 0.2, 0.5, 0.58, 0.7],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r * 0.96, sheen);

    canvas.drawCircle(c, r * labelFraction, Paint()..color = label);
    // Spindle hole.
    canvas.drawCircle(
        c, max(0.8, r * 0.05), Paint()..color = const Color(0xFF141416));
  }

  @override
  bool shouldRepaint(_VinylPainter oldDelegate) => oldDelegate.label != label;
}
