import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../app/theme/halo_motion.dart';
import '../../../data/location/location_tracker.dart';
import '../../../data/workouts/workout_session.dart';
import '../../../domain/route.dart';
import '../../../domain/workout.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../presentation/custom_workout_sheet.dart' show stepColor;
import '../widgets/route_map.dart';
import '../widgets/route_sections.dart';
import 'workout_controller.dart';

/// The live workout, full screen, growing out of its pill and back.
///
/// The same container transform as the Music player: one value from 0 (the
/// pill above the tab bar) to 1 (the whole screen) drives the rectangle, the
/// corners and the content, and it is a spring the finger can catch and throw
/// in either direction, never a transition with a fixed start and end.
class WorkoutLayer extends StatefulWidget {
  const WorkoutLayer({
    super.key,
    required this.controller,
    required this.pillRect,
  });

  final WorkoutController controller;

  /// Where the pill is on screen right now, to grow from and shrink to.
  final Rect? Function() pillRect;

  @override
  State<WorkoutLayer> createState() => _WorkoutLayerState();
}

class _WorkoutLayerState extends State<WorkoutLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    lowerBound: -0.2,
    upperBound: 1.2,
  )..addListener(() => setState(() {}));

  Rect? _from;

  /// Thrown motion overshoots a little; this one is always thrown or tapped.
  static final SpringDescription _spring =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 420),
        bounce: 0.14,
      );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    // Placed, not animated: nothing may read the MediaQuery before initState
    // returns, and a layer built already open has nowhere to grow from.
    _t.value = widget.controller.expanded ? 1 : 0;
  }

  @override
  void didUpdateWidget(WorkoutLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _t.dispose();
    super.dispose();
  }

  void _sync() {
    final target = widget.controller.expanded ? 1.0 : 0.0;
    if (target == 0) _from = widget.pillRect() ?? _from;
    if (target == 1 && _t.value <= 0.001) {
      // Growing from the pill: measure it now, before it is covered.
      _from = widget.pillRect() ?? _from;
    }
    _springTo(target);
  }

  void _springTo(double target, {double velocity = 0}) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _t.value = target;
      return;
    }
    _t.animateWith(SpringSimulation(_spring, _t.value, target, velocity));
  }

  void _drag(double dy, double height) {
    _t.stop();
    _t.value = (_t.value - dy / height).clamp(0.0, 1.0);
  }

  void _release(double velocity, double height) {
    final controller = widget.controller;
    final flung = velocity.abs() > 500;
    final close = flung ? velocity > 0 : _t.value < 0.7;
    if (close) {
      _from = widget.pillRect() ?? _from;
      controller.minimize();
      _springTo(0, velocity: -velocity / height);
    } else {
      _springTo(1, velocity: -velocity / height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.session;
    final t = _t.value;
    if (session == null || t <= 0.001) return const SizedBox.shrink();

    final size = MediaQuery.sizeOf(context);
    final full = Offset.zero & size;
    final from =
        _from ??
        Rect.fromLTWH(
          HaloMetrics.tabBarHorizontalPadding,
          size.height - 170,
          size.width - HaloMetrics.tabBarHorizontalPadding * 2,
          50,
        );
    final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final rect = Rect.lerp(from, full, t)!;
    final radius = lerpDouble(from.height / 2, 0, eased)!;
    final contentOpacity = ((t - 0.4) / 0.5).clamp(0.0, 1.0);

    return Stack(
      children: [
        // The page behind darkens as the layer rises.
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: const Color(
                0xFF000000,
              ).withValues(alpha: 0.4 * eased.clamp(0.0, 1.0)),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: rect,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: session.phase == SessionPhase.ended
                ? null
                : (d) => _drag(d.delta.dy, size.height),
            onVerticalDragEnd: session.phase == SessionPhase.ended
                ? null
                : (d) => _release(d.velocity.pixelsPerSecond.dy, size.height),
            child: ClipRSuperellipse(
              borderRadius: BorderRadius.circular(radius),
              child: ColoredBox(
                color: HaloColors.background.resolveFrom(context),
                // Laid out at full size from the first frame and clipped to
                // the growing rectangle, so nothing reflows on the way up.
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minWidth: size.width,
                  maxWidth: size.width,
                  minHeight: size.height,
                  maxHeight: size.height,
                  child: Opacity(
                    opacity: contentOpacity,
                    child: ListenableBuilder(
                      listenable: session,
                      builder: (context, _) => switch (session.phase) {
                        SessionPhase.countdown => _Countdown(
                          onSkip: widget.controller.skipCountdown,
                        ),
                        SessionPhase.ended => _Summary(
                          session: session,
                          controller: widget.controller,
                        ),
                        _ => _Live(
                          session: session,
                          onMinimize: widget.controller.minimize,
                        ),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Countdown ──────────────────────────────────────────────────────────────

/// 3, 2, 1 inside a ring that empties with them. Tap to skip.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.onSkip});

  final VoidCallback onSkip;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: WorkoutSession.countdownLength,
  )..forward();

  int _shown = 3;

  @override
  void initState() {
    super.initState();
    _clock.addListener(() {
      final remaining = 3 - (_clock.value * 3).floor();
      if (remaining != _shown && remaining > 0) {
        HapticFeedback.lightImpact();
        setState(() => _shown = remaining);
      }
    });
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onSkip,
      child: Center(
        child: SizedBox.square(
          dimension: 240,
          child: AnimatedBuilder(
            animation: _clock,
            builder: (context, _) => CustomPaint(
              painter: _CountdownRing(
                progress: 1 - _clock.value,
                color: accent,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: Tween(begin: 1.6, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Text(
                    '$_shown',
                    key: ValueKey(_shown),
                    style: TextStyle(
                      color: accent,
                      fontSize: 120,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownRing extends CustomPainter {
  _CountdownRing({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    canvas
      ..drawArc(
        arc,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = HaloColors.ringTrack(color),
      )
      ..drawArc(
        arc,
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
  bool shouldRepaint(_CountdownRing oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ── Live ───────────────────────────────────────────────────────────────────

class _Live extends StatelessWidget {
  const _Live({required this.session, required this.onMinimize});

  final WorkoutSession session;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final accent = HaloColors.accent.resolveFrom(context);
    final paused = session.phase == SessionPhase.paused;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        HaloMetrics.pagePadding,
        padding.top + 8,
        HaloMetrics.pagePadding,
        padding.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: HaloMetrics.barButtonSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  session.intervals?.workout.name ?? session.type.title,
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: HaloMetrics.barTitleSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _CircleButton(
                    icon: CupertinoIcons.chevron_down,
                    label: 'Minimise',
                    onTap: onMinimize,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: session.followsGps
                ? _LivePages(session: session)
                : _Readout(session: session),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BigControl(
                icon: CupertinoIcons.xmark,
                label: 'End',
                tint: CupertinoColors.systemRed.resolveFrom(context),
                ink: const Color(0xFFFFFFFF),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  session.end();
                },
              ),
              _BigControl(
                icon: paused
                    ? CupertinoIcons.play_fill
                    : CupertinoIcons.pause_fill,
                label: paused ? 'Resume' : 'Pause',
                tint: accent,
                ink: HaloColors.onAccent.resolveFrom(context),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  paused ? session.resume() : session.pause();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The time, the goal and the numbers: the live workout's main page.
class _Readout extends StatelessWidget {
  const _Readout({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    final paused = session.phase == SessionPhase.paused;
    final progress = session.goalProgress;
    final note = switch (session.locationAccess) {
      LocationAccess.denied =>
        'Location is off for Halo, so distance comes '
            'from your steps.',
      LocationAccess.serviceOff =>
        'Location Services are off, so distance comes from your steps.',
      _ => session.followsGps && !session.hasRoute ? 'Finding GPS…' : null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        // Says it is paused without hiding the time it paused at.
        AnimatedOpacity(
          opacity: paused ? 1 : 0,
          duration: HaloMotion.of(context, HaloMotion.controlSwapDuration),
          child: Text(
            session.autoPaused ? 'AUTO-PAUSED' : 'PAUSED',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HaloColors.secondaryLabelOf(context),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            Format.clock(session.elapsed),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent,
              fontSize: 88,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (progress != null) ...[
          const SizedBox(height: 8),
          _GoalBar(progress: progress, label: session.goal.describe),
        ],
        if (session.intervals != null) ...[
          const SizedBox(height: 16),
          IntervalCard(session: session),
        ],
        const SizedBox(height: 28),
        _Metrics(session: session),
        if (note != null) ...[
          const SizedBox(height: 18),
          Text(
            note,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HaloColors.secondaryLabelOf(context),
              fontSize: 13,
            ),
          ),
        ],
        const Spacer(flex: 2),
      ],
    );
  }
}

/// For a GPS workout: the readout, and a swipe away, the map.
class _LivePages extends StatefulWidget {
  const _LivePages({required this.session});

  final WorkoutSession session;

  @override
  State<_LivePages> createState() => _LivePagesState();
}

class _LivePagesState extends State<_LivePages> {
  final PageController _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = HaloColors.labelOf(context);

    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pages,
            onPageChanged: (page) {
              HapticFeedback.selectionClick();
              setState(() => _page = page);
            },
            children: [
              _Readout(session: widget.session),
              _LiveMap(session: widget.session),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: _page == 0 ? 'Page 1 of 2' : 'Page 2 of 2',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 2; i++)
                AnimatedContainer(
                  duration: HaloMotion.of(
                    context,
                    HaloMotion.controlSwapDuration,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: label.withValues(alpha: i == _page ? 0.9 : 0.25),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The route so far, following the phone, with the time and distance over it
/// on glass: the one piece of chrome on the page, floating over content.
class _LiveMap extends StatelessWidget {
  const _LiveMap({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final speed = session.type == WorkoutType.outdoorCycle;
    final pace = session.currentPace ?? session.pace;
    final cells = <(String, String)>[
      (Format.clock(session.elapsed), 'TIME'),
      (session.distanceKm.toStringAsFixed(2), 'KM'),
      if (speed)
        (pace == null ? '—' : SplitsCard.kmh(pace).toStringAsFixed(1), 'KM/H')
      else
        (pace == null ? '—' : Format.pace(pace), 'PACE'),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(HaloMetrics.cardRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: RouteMap(
                route: session.route,
                position: session.position,
                follow: true,
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              top: 10,
              child: GlassContainer(
                shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                settings: HaloGlass.of(context),
                quality: HaloGlass.quality,
                useOwnLayer: true,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    for (final (value, unit) in cells)
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              value,
                              style: TextStyle(
                                color: HaloColors.labelOf(context),
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            Text(
                              unit,
                              style: TextStyle(
                                color: HaloColors.secondaryLabelOf(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A custom workout's step under way: what it is, what is left of it, and
/// what comes next.
class IntervalCard extends StatelessWidget {
  const IntervalCard({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final tracker = session.intervals!;
    final segment = tracker.current;
    final next = tracker.next;
    final label = HaloColors.labelOf(context);
    final secondary = HaloColors.secondaryLabelOf(context);
    if (segment == null) {
      return HaloCard(
        child: Row(
          children: [
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: HaloColors.accent.resolveFrom(context),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Every step done. End when you are ready.',
                style: TextStyle(color: label, fontSize: 17),
              ),
            ),
          ],
        ),
      );
    }
    final color = stepColor(context, segment.step.kind);
    final left = tracker.timeLeft;
    final metres = tracker.metresLeft;
    final remaining = left != null
        ? Format.clock(Duration(seconds: (left.inMilliseconds / 1000).ceil()))
        : metres! >= 1000
        ? '${(metres / 1000).toStringAsFixed(2)} km'
        : '$metres m';

    return HaloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  segment.label.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Text(
                '${tracker.index + 1}/${tracker.segments.length}',
                style: TextStyle(
                  color: secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  remaining,
                  style: TextStyle(
                    color: label,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Next step',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    session.skipSegment();
                  },
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    margin: const EdgeInsets.only(bottom: 6),
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: HaloColors.fill.resolveFrom(context),
                      shape: const StadiumBorder(),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Skip',
                          style: TextStyle(
                            color: label,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.forward_end_fill,
                          size: 13,
                          color: label,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ProgressBar(value: tracker.progress, color: color),
          if (next != null) ...[
            const SizedBox(height: 8),
            Text(
              'Next: ${next.label} · ${next.step.describe}',
              style: TextStyle(color: secondary, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalBar extends StatelessWidget {
  const _GoalBar({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    return Column(
      children: [
        ClipRSuperellipse(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: HaloColors.ringTrack(accent)),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: ColoredBox(color: accent),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          progress >= 1 ? 'Goal reached · $label' : 'Goal · $label',
          style: TextStyle(
            color: HaloColors.secondaryLabelOf(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// The running numbers, two to a row.
class _Metrics extends StatelessWidget {
  const _Metrics({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final pace = session.pace;
    final type = session.type;
    final current = session.currentPace ?? pace;
    final distance = (
      session.distanceKm.toStringAsFixed(2),
      'KM',
      HaloColors.activeHours.resolveFrom(context),
    );
    final cells = <(String, String, Color)>[
      (
        Format.integer(session.activeKcal),
        'ACTIVE KCAL',
        HaloColors.move.resolveFrom(context),
      ),
      if (type.gps) ...[
        distance,
        if (type == WorkoutType.outdoorCycle)
          (
            current == null ? '—' : SplitsCard.kmh(current).toStringAsFixed(1),
            'KM/H',
            HaloColors.labelOf(context),
          )
        else
          (
            current == null ? '—' : Format.pace(current),
            'PACE /KM',
            HaloColors.labelOf(context),
          ),
        (
          Format.integer(session.elevationGainM),
          'M CLIMBED',
          CupertinoColors.systemOrange.resolveFrom(context),
        ),
      ] else if (type.steps) ...[
        distance,
        (
          Format.integer(session.steps),
          'STEPS',
          HaloColors.steps.resolveFrom(context),
        ),
        (
          pace == null ? '—' : Format.pace(pace),
          'PACE /KM',
          HaloColors.labelOf(context),
        ),
      ],
    ];

    return Wrap(
      runSpacing: 18,
      children: [
        for (final (value, unit, color) in cells)
          FractionallySizedBox(
            widthFactor: 0.5,
            child: Column(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A 48pt glass circle on the layer.
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      icon: Icon(icon),
      onTap: onTap,
      label: label,
      width: HaloMetrics.barButtonSize,
      height: HaloMetrics.barButtonSize,
      iconSize: HaloMetrics.barButtonSize * HaloMetrics.barGlyphRatio,
      iconColor: HaloColors.labelOf(context),
      settings: HaloGlass.of(context),
      quality: HaloGlass.quality,
      useOwnLayer: true,
    );
  }
}

/// A large tinted glass circle with its label under it: End, Pause.
class _BigControl extends StatelessWidget {
  const _BigControl({
    required this.icon,
    required this.label,
    required this.tint,
    required this.ink,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final Color ink;
  final VoidCallback onTap;

  static const double _size = 84;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassButton(
          icon: Icon(icon),
          onTap: onTap,
          label: label,
          width: _size,
          height: _size,
          iconSize: 34,
          iconColor: ink,
          settings: HaloGlass.tinted(tint),
          quality: HaloGlass.quality,
          useOwnLayer: true,
        ),
        // The label is part of the target: a thumb aims at the word as often
        // as at the circle above it.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              label,
              style: TextStyle(
                color: HaloColors.secondaryLabelOf(context),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Summary ────────────────────────────────────────────────────────────────

/// The finished workout: its numbers, how hard it felt, and Save or Discard.
class _Summary extends StatefulWidget {
  const _Summary({required this.session, required this.controller});

  final WorkoutSession session;
  final WorkoutController controller;

  @override
  State<_Summary> createState() => _SummaryState();
}

class _SummaryState extends State<_Summary> {
  int? _effort;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final padding = MediaQuery.paddingOf(context);
    final accent = HaloColors.accent.resolveFrom(context);

    final type = session.type;
    final pace = session.pace;
    final rows = <(String, String)>[
      ('Workout Time', Format.clock(session.elapsed)),
      ('Active Energy', '${Format.integer(session.activeKcal)} kcal'),
      if (type.hasDistance && session.distanceKm > 0)
        ('Distance', '${session.distanceKm.toStringAsFixed(2)} km'),
      if (type.steps && session.steps > 0)
        ('Steps', Format.integer(session.steps)),
      if (pace != null && type == WorkoutType.outdoorCycle)
        ('Avg. Speed', '${SplitsCard.kmh(pace).toStringAsFixed(1)} km/h')
      else if (pace != null)
        ('Avg. Pace', '${Format.pace(pace)} /km'),
      if (session.hasRoute)
        ('Elevation Gain', '${Format.integer(session.elevationGainM)} m'),
    ];
    final splits = session.hasRoute ? session.splits : const <RouteSplit>[];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        HaloMetrics.cardPadding,
        padding.top + 24,
        HaloMetrics.cardPadding,
        padding.bottom + 24,
      ),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
            ),
            child: Icon(session.type.icon, size: 38, color: accent),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          session.type.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: HaloColors.labelOf(context),
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        Text(
          'Workout Complete',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: HaloColors.secondaryLabelOf(context),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 24),
        if (session.hasRoute) ...[
          RouteMapCard(route: session.route),
          const SizedBox(height: HaloMetrics.cardGap),
        ],
        HaloCard(
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Container(
                    height: HaloMetrics.separatorThickness,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    color: HaloColors.separatorOf(context),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rows[i].$1,
                        style: TextStyle(
                          color: HaloColors.secondaryLabelOf(context),
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      rows[i].$2,
                      style: TextStyle(
                        color: HaloColors.labelOf(context),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (splits.isNotEmpty) ...[
          const WorkoutSectionTitle('Splits'),
          SplitsCard(splits: splits, type: type),
        ],
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'HOW HARD WAS IT?',
            style: TextStyle(
              color: HaloColors.secondaryLabelOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        HaloCard(
          padding: const EdgeInsets.all(12),
          child: _EffortPicker(
            value: _effort,
            onChanged: (v) => setState(() => _effort = v),
          ),
        ),
        const SizedBox(height: 28),
        FilledCapsuleButton(
          label: 'Save Workout',
          height: 54,
          onTap: () async {
            if (_saving) return;
            _saving = true;
            HapticFeedback.mediumImpact();
            await widget.controller.save(effort: _effort);
          },
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          onPressed: widget.controller.discard,
          child: Text(
            'Discard',
            style: TextStyle(
              color: CupertinoColors.destructiveRed.resolveFrom(context),
              fontSize: 17,
            ),
          ),
        ),
      ],
    );
  }
}

/// Effort from 1 to 10, as ten cells, the way Fitness rates a workout.
class _EffortPicker extends StatelessWidget {
  const _EffortPicker({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  static String describe(int effort) => switch (effort) {
    <= 3 => 'Easy',
    <= 6 => 'Moderate',
    <= 8 => 'Hard',
    _ => 'All Out',
  };

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    final value = this.value;

    return Column(
      children: [
        Row(
          children: [
            for (var i = 1; i <= 10; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(i);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AnimatedContainer(
                      duration: HaloMotion.of(
                        context,
                        HaloMotion.controlSwapDuration,
                      ),
                      height: 36,
                      decoration: ShapeDecoration(
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        color: value != null && i <= value
                            ? Color.lerp(
                                accent,
                                CupertinoColors.systemRed.resolveFrom(context),
                                (i - 1) / 9,
                              )
                            : HaloColors.fill.resolveFrom(context),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$i',
                        style: TextStyle(
                          color: value != null && i <= value
                              ? const Color(0xFF000000)
                              : HaloColors.secondaryLabelOf(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value == null ? 'Tap to rate' : describe(value),
          style: TextStyle(
            color: HaloColors.secondaryLabelOf(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
