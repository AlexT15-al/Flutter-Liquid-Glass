import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../shared/format.dart';

/// The rest between two sets, counting down to [end].
///
/// A glass capsule floating over the session: a ring that empties, the time
/// left, what comes next, 15 seconds less or more, and Skip. Three light taps
/// in the last three seconds and a firm one at zero, so the phone can stay on
/// the bench.
class RestTimer extends StatefulWidget {
  const RestTimer({
    super.key,
    required this.end,
    required this.total,
    required this.next,
    required this.onAdjust,
    required this.onDone,
  });

  /// When the rest is over.
  final DateTime end;

  /// The whole rest, for the ring.
  final Duration total;

  /// What comes after it: "Set 3 · Squat".
  final String next;

  /// Moves the end by this many seconds.
  final ValueChanged<int> onAdjust;

  /// The rest ran out, or was skipped.
  final VoidCallback onDone;

  static const double height = 64;

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _left = Duration.zero;
  int _lastSecond = -1;

  @override
  void initState() {
    super.initState();
    _left = _remaining();
    _ticker = createTicker((_) => _tick())..start();
  }

  Duration _remaining() {
    final left = widget.end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void _tick() {
    final left = _remaining();
    final second = (left.inMilliseconds / 1000).ceil();
    if (second != _lastSecond) {
      if (second <= 3 && second > 0 && _lastSecond > second) {
        HapticFeedback.lightImpact();
      }
      _lastSecond = second;
    }
    if (left == Duration.zero) {
      _ticker.stop();
      HapticFeedback.heavyImpact();
      widget.onDone();
      return;
    }
    setState(() => _left = left);
  }

  @override
  void didUpdateWidget(RestTimer old) {
    super.didUpdateWidget(old);
    if (old.end != widget.end) {
      _lastSecond = -1;
      if (!_ticker.isActive) _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    final label = HaloColors.labelOf(context);
    final secondary = HaloColors.secondaryLabelOf(context);
    final total = widget.total.inMilliseconds;
    final progress = total == 0 ? 0.0 : _left.inMilliseconds / total;
    final shown = Duration(seconds: (_left.inMilliseconds / 1000).ceil());

    return Semantics(
      liveRegion: true,
      label: 'Rest, ${Format.clock(shown)} left',
      child: GlassContainer(
        shape: const LiquidRoundedSuperellipse(borderRadius: RestTimer.height),
        settings: HaloGlass.of(context),
        quality: HaloGlass.quality,
        useOwnLayer: true,
        child: SizedBox(
          height: RestTimer.height,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CustomPaint(
                    painter: _RingPainter(
                      value: progress.clamp(0.0, 1.0),
                      color: accent,
                      track: HaloColors.ringTrack(accent),
                    ),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.timer,
                        size: 18,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Format.clock(shown),
                        style: TextStyle(
                          color: label,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        'Next: ${widget.next}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: secondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _RoundButton(
                  label: '−15',
                  semantics: '15 seconds less',
                  onTap: () => widget.onAdjust(-15),
                ),
                const SizedBox(width: 6),
                _RoundButton(
                  label: '+15',
                  semantics: '15 seconds more',
                  onTap: () => widget.onAdjust(15),
                ),
                const SizedBox(width: 6),
                _RoundButton(
                  label: 'Skip',
                  semantics: 'Skip rest',
                  filled: true,
                  onTap: () {
                    _ticker.stop();
                    widget.onDone();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.label,
    required this.semantics,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final String semantics;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: 44,
          constraints: const BoxConstraints(minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: filled ? accent : HaloColors.fill.resolveFrom(context),
            shape: const StadiumBorder(),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: filled
                  ? HaloColors.onAccent.resolveFrom(context)
                  : HaloColors.labelOf(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color, required this.track});

  final double value;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.5;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}
