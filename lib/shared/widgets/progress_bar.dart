import 'package:flutter/widgets.dart';

import '../../app/theme/halo_colors.dart';

/// A thin rounded bar filled to [value] (0 to 1) over a faint track of the
/// same colour.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarPainter(value: value.clamp(0.0, 1.0), color: color),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = HaloColors.ringTrack(color),
    );
    if (value <= 0) return;
    final width = (size.width * value).clamp(size.height, size.width);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, size.height), radius),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.value != value || old.color != color;
}
