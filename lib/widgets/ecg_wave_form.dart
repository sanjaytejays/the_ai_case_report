import 'package:flutter/material.dart';

class ECGWaveform extends StatefulWidget {
  final bool isActive;
  const ECGWaveform({super.key, required this.isActive});

  @override
  State<ECGWaveform> createState() => _ECGWaveformState();
}

class _ECGWaveformState extends State<ECGWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Speed of the scan
    );

    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(ECGWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.value = 0.0; // Reset to flat line
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
    final color = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 100,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ECGPainter(
              progress: _controller.value,
              color: color,
              isActive: widget.isActive,
            ),
          );
        },
      ),
    );
  }
}

class _ECGPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isActive;

  _ECGPainter({
    required this.progress,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Add a shadow/glow effect for that "Monitor" look
    final glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    final centerY = size.height / 2;

    // If not recording, just draw a flat line
    if (!isActive) {
      path.moveTo(0, centerY);
      path.lineTo(size.width, centerY);
      canvas.drawPath(path, paint);
      return;
    }

    // The ECG Pattern: Flat -> P -> Flat -> Q -> R -> S -> Flat -> T -> Flat
    // Represented as (X-relative-step, Y-amplitude)
    final List<Offset> beatPattern = [
      const Offset(0, 0), // Start
      const Offset(20, 0), // Flat
      const Offset(25, -10), // P wave up
      const Offset(30, 0), // P wave down
      const Offset(35, 0), // Flat
      const Offset(38, 5), // Q wave down
      const Offset(42, -50), // R wave UP (Spike)
      const Offset(46, 15), // S wave down
      const Offset(50, 0), // Back to baseline
      const Offset(55, 0), // Flat
      const Offset(60, -15), // T wave up
      const Offset(70, 0), // T wave down
      const Offset(100, 0), // Long Flat
    ];

    path.moveTo(0, centerY);

    // We draw multiple cycles to fill the width
    double totalWidth = 0;
    double patternWidth = 100.0; // Width of one beat cycle defined above
    double shiftX = -progress * patternWidth * 2; // Speed of scroll

    // Start drawing off-screen to the left so it flows in smoothly
    double currentX = shiftX;

    // Loop until we cover the screen width
    while (currentX < size.width) {
      for (var point in beatPattern) {
        double x = currentX + point.dx;
        double y = centerY + point.dy;

        // Simple smoothing: if it's the first point of a cycle, move; otherwise connect
        if (point == beatPattern.first) {
          // If path is empty (very first point), move to it.
          // Otherwise, lineTo ensures continuous connection between loops.
          if (currentX == shiftX) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        } else {
          path.lineTo(x, y);
        }
      }
      currentX += patternWidth;
    }

    // Draw the glow first
    canvas.drawPath(path, glowPaint);
    // Draw the sharp line on top
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ECGPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isActive != isActive;
  }
}
