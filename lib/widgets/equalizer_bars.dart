import 'dart:math' as math;
import 'package:flutter/material.dart';

class EqualizerBars extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double height;
  final int barCount;

  const EqualizerBars({
    super.key,
    required this.isPlaying,
    this.color = const Color(0xFF8B5CF6),
    this.height = 18.0,
    this.barCount = 4,
  });

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.animateTo(0.2, duration: const Duration(milliseconds: 200));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.barCount, (index) {
            final phase = (index * 0.3);
            final value = widget.isPlaying
                ? (math.sin((_controller.value * 2 * math.pi) + phase).abs() *
                        0.7 +
                    0.3)
                : 0.25;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: widget.height * value,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
