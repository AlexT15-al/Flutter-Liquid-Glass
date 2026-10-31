import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/sleep.dart';
import '../../../shared/format.dart';
import '../sleep_controller.dart';
import 'night_page.dart';

/// The phone on the bed at night: a dim clock on black, the time to wake,
/// and a button that has to be held, so nothing ends the night by accident.
///
/// Always dark, whatever the app's appearance: it is looked at in a dark
/// room. Closing it leaves the night tracking.
class BedsidePage extends StatefulWidget {
  const BedsidePage({super.key});

  static Route<void> route() => PageRouteBuilder<void>(
    opaque: true,
    fullscreenDialog: true,
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => const BedsidePage(),
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );

  @override
  State<BedsidePage> createState() => _BedsidePageState();
}

class _BedsidePageState extends State<BedsidePage> {
  late final Timer _clock;
  bool _waking = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  Future<void> _wake() async {
    if (_waking) return;
    _waking = true;
    HapticFeedback.heavyImpact();
    final night = await SleepScope.read(context).stop();
    if (!mounted) return;
    if (night == null) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(NightPage.route(night));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final padding = MediaQuery.paddingOf(context);
    final since = SleepScope.of(context).since;
    const dim = Color(0xCCFFFFFF);
    const faint = Color(0x80FFFFFF);

    return CupertinoTheme(
      data: const CupertinoThemeData(brightness: Brightness.dark),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: ColoredBox(
          color: const Color(0xFF000000),
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
                  child: Builder(
                    builder: (context) => GlassButton(
                      icon: const Icon(CupertinoIcons.chevron_down),
                      label: 'Close',
                      onTap: () => Navigator.of(context).pop(),
                      width: HaloMetrics.barButtonSize,
                      height: HaloMetrics.barButtonSize,
                      iconSize:
                          HaloMetrics.barButtonSize * HaloMetrics.barGlyphRatio,
                      iconColor: dim,
                      settings: HaloGlass.of(context),
                      quality: HaloGlass.quality,
                      useOwnLayer: true,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  Format.timeOfDay(now),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: dim,
                    fontSize: 104,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -3,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  Format.longDate(now),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: faint, fontSize: 17),
                ),
                const SizedBox(height: 22),
                StreamBuilder<SleepSchedule>(
                  stream: HaloScope.preferencesOf(context).watchSleepSchedule(),
                  builder: (context, snapshot) {
                    final schedule = snapshot.data;
                    if (schedule == null) return const SizedBox(height: 20);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.sunrise_fill,
                          size: 18,
                          color: faint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Wake up ${Format.minutesOfDay(schedule.wakeMinutes)}',
                          style: const TextStyle(color: faint, fontSize: 15),
                        ),
                      ],
                    );
                  },
                ),
                const Spacer(),
                const _Tracking(),
                if (since != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Since ${Format.timeOfDay(since)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: faint, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 28),
                Center(child: _HoldToWake(onWake: _wake)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A slow pulse that says the night is being followed.
class _Tracking extends StatefulWidget {
  const _Tracking();

  @override
  State<_Tracking> createState() => _TrackingState();
}

class _TrackingState extends State<_Tracking>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = HaloColors.sleep.resolveFrom(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.3, end: 1.0).animate(_pulse),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Tracking your sleep',
          style: TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Wake Up, held for a second while a ring fills around it. Let go early
/// and the ring runs back.
class _HoldToWake extends StatefulWidget {
  const _HoldToWake({required this.onWake});

  final VoidCallback onWake;

  @override
  State<_HoldToWake> createState() => _HoldToWakeState();
}

class _HoldToWakeState extends State<_HoldToWake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onWake();
        });

  static const double _size = 92;

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _down() {
    HapticFeedback.lightImpact();
    _hold.forward();
  }

  void _up() {
    if (_hold.status != AnimationStatus.completed) _hold.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = HaloColors.sleep.resolveFrom(context);
    return Semantics(
      button: true,
      label: 'Hold to wake up',
      onTap: widget.onWake,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Listener(
            onPointerDown: (_) => _down(),
            onPointerUp: (_) => _up(),
            onPointerCancel: (_) => _up(),
            child: SizedBox.square(
              dimension: _size + 16,
              child: AnimatedBuilder(
                animation: _hold,
                builder: (context, child) => CustomPaint(
                  painter: _HoldRing(progress: _hold.value, color: color),
                  child: child,
                ),
                child: Center(
                  child: GlassButton(
                    icon: const Icon(CupertinoIcons.sun_max_fill),
                    label: 'Wake Up',
                    onTap: () {},
                    width: _size,
                    height: _size,
                    iconSize: 36,
                    iconColor: const Color(0xE6FFFFFF),
                    settings: HaloGlass.tinted(color),
                    quality: HaloGlass.quality,
                    useOwnLayer: true,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hold to Wake Up',
            style: TextStyle(
              color: Color(0x99FFFFFF),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldRing extends CustomPainter {
  _HoldRing({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    const stroke = 4.0;
    canvas.drawArc(
      (Offset.zero & size).deflate(stroke / 2),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_HoldRing old) =>
      old.progress != progress || old.color != color;
}
