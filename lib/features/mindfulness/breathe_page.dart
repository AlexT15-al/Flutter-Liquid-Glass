import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../app/halo_scope.dart';
import '../../app/theme/halo_metrics.dart';
import '../../domain/mindfulness.dart';
import '../../shared/widgets/glass_action_button.dart';
import 'mindful_shared.dart';

/// Breathe: a flower that opens as the lungs fill and closes as they empty,
/// in for four seconds and out for six, with light taps through each
/// in-breath to follow with the eyes closed.
class BreathePage extends StatefulWidget {
  const BreathePage({super.key});

  static Route<void> route() => sessionRoute<void>(const BreathePage());

  @override
  State<BreathePage> createState() => _BreathePageState();
}

class _BreathePageState extends State<BreathePage>
    with SingleTickerProviderStateMixin {
  static const _pattern = BreathPattern();
  static const _color = Color(0xFF5FE0D4);

  late final Ticker _ticker;
  int _minutes = 1;
  DateTime? _started;
  Duration _elapsed = Duration.zero;
  bool _finished = false;
  int _lastTap = -1;

  Duration get _length => Duration(minutes: _minutes);

  @override
  void initState() {
    super.initState();
    // Made here, not lazily: a page closed without starting would otherwise
    // first create it in dispose, after its context is gone.
    _ticker = createTicker(_tick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _start() {
    HapticFeedback.mediumImpact();
    setState(() {
      _started = DateTime.now();
      _elapsed = Duration.zero;
      _finished = false;
    });
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    if (elapsed >= _length) {
      _ticker.stop();
      _finish(_length);
      return;
    }
    final (inhaling, _) = _pattern.at(elapsed);
    // A light tap every half second while breathing in.
    final slot = elapsed.inMilliseconds ~/ 500;
    if (inhaling && slot != _lastTap) {
      _lastTap = slot;
      HapticFeedback.selectionClick();
    }
    setState(() => _elapsed = elapsed);
  }

  Future<void> _finish(Duration length) async {
    final start = _started;
    if (start == null || _finished) return;
    HapticFeedback.heavyImpact();
    setState(() => _finished = true);
    if (length >= const Duration(seconds: 30)) {
      await HaloScope.mindfulnessOf(context).addSession(
        MindfulSession(start: start, length: length, kind: MindfulKind.breathe),
      );
    }
  }

  void _close() {
    if (_ticker.isActive) {
      _ticker.stop();
      _finish(_elapsed);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final running = _started != null && !_finished;
    final (inhaling, lungs) = running ? _pattern.at(_elapsed) : (true, 0.0);
    final remaining = _length - _elapsed;

    return ColoredBox(
      color: const Color(0xFF02120F),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          HaloMetrics.pagePadding,
          padding.top + 8,
          HaloMetrics.pagePadding,
          padding.bottom + 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SessionCloseButton(onTap: _close),
            ),
            const Spacer(),
            SizedBox(
              height: 300,
              child: CustomPaint(
                painter: _Flower(
                  open: running ? lungs : (_finished ? 0.15 : 0.35),
                  turn: _elapsed.inMilliseconds / 30000,
                  color: _color,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _finished
                  ? 'Well Done'
                  : running
                  ? (inhaling ? 'Breathe In' : 'Breathe Out')
                  : 'Breathe',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 30,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _finished
                  ? '$_minutes min · ${_pattern.breathsIn(_length)} breaths'
                  : running
                  ? '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}'
                  : 'In for four, out for six. Follow the flower.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 17),
            ),
            const Spacer(),
            if (!running) ...[
              if (!_finished)
                DurationPicker(
                  minutes: const [1, 2, 3, 5],
                  selected: _minutes,
                  color: _color,
                  onChanged: (m) => setState(() => _minutes = m),
                ),
              const SizedBox(height: 20),
              GlassActionButton(
                label: _finished ? 'Done' : 'Start',
                icon: _finished
                    ? CupertinoIcons.checkmark_alt
                    : CupertinoIcons.play_fill,
                tint: _color,
                ink: const Color(0xFF00201C),
                onTap: _finished ? () => Navigator.of(context).pop() : _start,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Six translucent petals around a centre, spreading and swelling as [open]
/// goes from 0 to 1, the whole turning slowly.
class _Flower extends CustomPainter {
  _Flower({required this.open, required this.turn, required this.color});

  final double open;
  final double turn;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final max = math.min(size.width, size.height) / 2;
    final eased = Curves.easeInOut.transform(open.clamp(0.0, 1.0));
    final radius = max * (0.32 + 0.18 * eased);
    final spread = max * 0.5 * eased;
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = null;
    for (var i = 0; i < 6; i++) {
      final angle = turn * math.pi * 2 + i * math.pi / 3;
      final c = centre + Offset(math.cos(angle), math.sin(angle)) * spread;
      paint.shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.55),
          Color.lerp(
            color,
            const Color(0xFF2A7FD4),
            0.5,
          )!.withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: radius));
      canvas.drawCircle(c, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_Flower old) =>
      old.open != open || old.turn != turn || old.color != color;
}
