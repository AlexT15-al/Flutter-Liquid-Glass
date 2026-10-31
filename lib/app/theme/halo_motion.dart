import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Motion tokens, in Apple's two-parameter model.
///
/// - **Bounce** is the inverse of damping: `0` reaches the target and stops,
///   higher values overshoot.
/// - **Duration** is the response, how quickly the value converges. A spring
///   has no fixed length; its settle time falls out of the parameters.
///
/// Overshoot is only right when the gesture carried momentum: a flick, a
/// throw, a drag release. Something that simply appears does not bounce, so
/// [standard] is the default and [momentum] the exception.
///
/// `SpringDescription.withDurationAndBounce` is the factory the package's
/// `GlassSpring` presets use, so the app and the glass share one model.
abstract final class HaloMotion {
  // ── Springs ────────────────────────────────────────────────────────────────

  /// Critically damped, 0.4s response: the default for moving anything.
  static SpringDescription get standard =>
      GlassSpring.smooth(duration: const Duration(milliseconds: 400));

  /// A little overshoot, 0.4s response: only for motion a gesture threw.
  static SpringDescription get momentum =>
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 400),
        bounce: 0.2,
      );

  /// A ring or a gauge filling to its value. Slower than [standard] so the fill
  /// is something you watch rather than a jump; no bounce, because a value
  /// overshooting reads as the number being wrong for a moment.
  static SpringDescription get fill =>
      GlassSpring.smooth(duration: const Duration(milliseconds: 900));

  /// Modal sheets: 0.3s with a little bounce, Apple's published drawer values.
  static SpringDescription get sheet => SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 300),
    bounce: 0.2,
  );

  // ── Curves, for implicit animations ────────────────────────────────────────

  /// Stand-in for [standard] where a widget wants a curve.
  static const standardCurve = Curves.easeOutCubic;
  static const standardDuration = Duration(milliseconds: 350);

  /// Cross-fade between two tabs. Short: the tab bar's indicator is the motion
  /// the eye follows, and a slow body behind it reads as lag.
  static const tabSwitchDuration = Duration(milliseconds: 200);

  /// A control changing in place: a value swapping, a glyph filling.
  static const controlSwapDuration = Duration(milliseconds: 250);

  // ── Press feedback ─────────────────────────────────────────────────────────

  /// The highlight arrives on pointer-down and has to be effectively instant;
  /// latency here is what makes an interface feel dead.
  static const pressInDuration = Duration(milliseconds: 80);

  /// Release fades slower, so a tap still reads as a tap.
  static const pressOutDuration = Duration(milliseconds: 200);

  static const pressCurve = Curves.easeOut;

  /// How far a card sinks under the finger.
  static const double pressScale = 0.97;

  // ── Accessibility ──────────────────────────────────────────────────────────

  /// Collapses a duration to zero under Reduce Motion. Colour and opacity
  /// changes still carry meaning and stay; travel and springing go.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
