import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../app/halo_scope.dart';
import '../../app/theme/halo_metrics.dart';
import '../../domain/mindfulness.dart';
import '../../shared/widgets/glass_action_button.dart';
import 'mindful_shared.dart';

/// A meditation timer: pick a length, sit, a ring empties, a firm tap at the
/// end. Pausing stops the clock; ending early keeps the minutes sat.
class MeditatePage extends StatefulWidget {
  const MeditatePage({super.key});

  static Route<void> route() => sessionRoute<void>(const MeditatePage());

  @override
  State<MeditatePage> createState() => _MeditatePageState();
}

class _MeditatePageState extends State<MeditatePage>
    with SingleTickerProviderStateMixin {
  static const _color = Color(0xFFB59CFF);

  late final Ticker _ticker;
  int _minutes = 10;
  DateTime? _started;
  Duration _banked = Duration.zero;
  Duration _run = Duration.zero;
  bool _paused = false;
  bool _finished = false;

  Duration get _length => Duration(minutes: _minutes);
  Duration get _elapsed => _banked + _run;

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
      _banked = Duration.zero;
      _run = Duration.zero;
      _finished = false;
      _paused = false;
    });
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    _run = elapsed;
    if (_elapsed >= _length) {
      _ticker.stop();
      _finish();
      return;
    }
    setState(() {});
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    if (_paused) {
      _ticker.start();
    } else {
      _banked += _run;
      _run = Duration.zero;
      _ticker.stop();
    }
    setState(() => _paused = !_paused);
  }

  Future<void> _finish() async {
    final start = _started;
    if (start == null || _finished) return;
    final sat = _elapsed > _length ? _length : _elapsed;
    _ticker.stop();
    HapticFeedback.heavyImpact();
    setState(() => _finished = true);
    if (sat >= const Duration(seconds: 30)) {
      await HaloScope.mindfulnessOf(context).addSession(
        MindfulSession(start: start, length: sat, kind: MindfulKind.meditate),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final running = _started != null && !_finished;
    final remaining = _length - _elapsed;
    final progress = running
        ? _elapsed.inMilliseconds / _length.inMilliseconds
        : 0.0;
    final sat = _elapsed > _length ? _length : _elapsed;

    return ColoredBox(
      color: const Color(0xFF0B0716),
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
              child: SessionCloseButton(
                onTap: () {
                  if (running) _finish();
                  Navigator.of(context).pop();
                },
              ),
            ),
            const Spacer(),
            Center(
              child: SizedBox.square(
                dimension: 260,
                child: CustomPaint(
                  painter: _Ring(value: 1 - progress, color: _color),
                  child: Center(
                    child: Text(
                      _finished
                          ? '${sat.inMinutes} min'
                          : running
                          ? '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}'
                          : '$_minutes:00',
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 56,
                        fontWeight: FontWeight.w300,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _finished
                  ? 'Well Done'
                  : running
                  ? (_paused ? 'Paused' : 'Sit comfortably. Let thoughts pass.')
                  : 'Meditate',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (!running && !_finished) ...[
              DurationPicker(
                minutes: const [5, 10, 15, 20],
                selected: _minutes,
                color: _color,
                onChanged: (m) => setState(() => _minutes = m),
              ),
              const SizedBox(height: 20),
              GlassActionButton(
                label: 'Start',
                icon: CupertinoIcons.play_fill,
                tint: _color,
                ink: const Color(0xFF150A33),
                onTap: _start,
              ),
            ] else if (running)
              Row(
                children: [
                  Expanded(
                    child: GlassActionButton(
                      label: _paused ? 'Resume' : 'Pause',
                      icon: _paused
                          ? CupertinoIcons.play_fill
                          : CupertinoIcons.pause_fill,
                      tint: const Color(0x40FFFFFF),
                      ink: const Color(0xFFFFFFFF),
                      onTap: _togglePause,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassActionButton(
                      label: 'End',
                      tint: _color,
                      ink: const Color(0xFF150A33),
                      onTap: _finish,
                    ),
                  ),
                ],
              )
            else
              GlassActionButton(
                label: 'Done',
                icon: CupertinoIcons.checkmark_alt,
                tint: _color,
                ink: const Color(0xFF150A33),
                onTap: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends CustomPainter {
  _Ring({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withValues(alpha: 0.18),
    );
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_Ring old) => old.value != value || old.color != color;
}
