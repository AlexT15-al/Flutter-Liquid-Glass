import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../data/workouts/workout_session.dart';
import '../../../shared/format.dart';

/// The workout in progress, minimised: a glass pill above the tab bar, the
/// tab bar's bottom accessory, as Music keeps its mini player there.
///
/// Tap or swipe it up to grow the workout back to full screen. The pause
/// button works from here, so a stop at a crossing needs no detour.
class WorkoutPill extends StatefulWidget {
  const WorkoutPill({
    super.key,
    required this.session,
    required this.onOpen,
    required this.height,
  });

  final WorkoutSession session;
  final VoidCallback onOpen;
  final double height;

  @override
  State<WorkoutPill> createState() => _WorkoutPillState();
}

class _WorkoutPillState extends State<WorkoutPill> {
  double _dragUp = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dragUp < 0) return;
    _dragUp -= details.delta.dy;
    if (_dragUp >= 16) {
      // Spent: the finger is still down and more updates are coming.
      _dragUp = -1;
      widget.onOpen();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragUp >= 0 && (details.primaryVelocity ?? 0) <= -220) {
      widget.onOpen();
    }
    _dragUp = 0;
  }

  @override
  Widget build(BuildContext context) {
    final accent = HaloColors.accent.resolveFrom(context);
    final label = HaloColors.labelOf(context);

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onVerticalDragStart: (_) => _dragUp = 0,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: GlassButton.custom(
        onTap: widget.onOpen,
        label: 'Open workout',
        width: double.infinity,
        height: widget.height,
        shape: LiquidRoundedRectangle(borderRadius: widget.height / 2),
        settings: HaloGlass.tabBar(context),
        quality: HaloGlass.quality,
        useOwnLayer: true,
        child: ListenableBuilder(
          listenable: widget.session,
          builder: (context, _) {
            final session = widget.session;
            final paused = session.phase == SessionPhase.paused;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                    child: Icon(
                      session.type.icon,
                      size: 20,
                      color: HaloColors.onAccent.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.type.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: label,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          paused
                              ? 'Paused · ${Format.clock(session.elapsed)}'
                              : Format.clock(session.elapsed),
                          style: TextStyle(
                            color: accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      paused ? session.resume() : session.pause();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        paused
                            ? CupertinoIcons.play_fill
                            : CupertinoIcons.pause_fill,
                        size: 22,
                        color: label,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
