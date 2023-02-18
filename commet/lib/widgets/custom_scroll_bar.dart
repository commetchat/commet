import 'dart:math';

import 'package:flutter/material.dart';

class CustomScrollbar extends StatefulWidget {
  final ScrollController scrollController;
  final double height;
  final Color backgroundColor;
  final Color thumbColor;

  const CustomScrollbar({
    Key? key,
    required this.scrollController,
    this.height = 50.0,
    this.backgroundColor = Colors.transparent,
    this.thumbColor = Colors.grey,
  }) : super(key: key);

  @override
  _CustomScrollbarState createState() => _CustomScrollbarState();
}

class _CustomScrollbarState extends State<CustomScrollbar> {
  double _thumbY = 0.0;
  double _scrollPercent = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    setState(() {
      _scrollPercent = widget.scrollController.offset /
          widget.scrollController.position.maxScrollExtent;
      _thumbY = (1 - _scrollPercent) * (widget.height - 20);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        double y = details.localPosition.dy;
        double percent = y / widget.height;

        percent = min(percent, 1);
        percent = max(percent, 0);
        percent = 1 - percent;
        widget.scrollController
            .jumpTo(percent * widget.scrollController.position.maxScrollExtent);
      },
      onVerticalDragUpdate: (details) {
        double y = details.localPosition.dy;
        double percent = y / widget.height;
        percent = min(percent, 1);
        percent = max(percent, 0);
        percent = 1 - percent;

        widget.scrollController
            .jumpTo(percent * widget.scrollController.position.maxScrollExtent);
      },
      child: Container(
        height: widget.height,
        width: 20.0,
        color: widget.backgroundColor,
        child: CustomPaint(
          painter: ScrollThumbPainter(
            thumbY: _thumbY,
            thumbColor: widget.thumbColor,
          ),
        ),
      ),
    );
  }
}

class ScrollThumbPainter extends CustomPainter {
  final double thumbY;
  final Color thumbColor;

  ScrollThumbPainter({
    required this.thumbY,
    required this.thumbColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, thumbY + 10),
      10.0,
      thumbPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
