import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../app/theme/halo_glass.dart';
import '../../app/theme/halo_metrics.dart';

/// Where on the mood scale someone is, as a colour: violet for unpleasant,
/// a quiet blue for neutral, warm orange for pleasant.
Color moodColor(int valence) {
  const stops = [
    Color(0xFF7A5AF8),
    Color(0xFF6E7BF2),
    Color(0xFF5B9BEA),
    Color(0xFF5AB8D8),
    Color(0xFF8CCB7A),
    Color(0xFFF2B33D),
    Color(0xFFFF8A1F),
  ];
  return stops[valence.clamp(0, 6)];
}

/// A full-screen, always-dark page for a session, its own close button in
/// the corner.
Route<T> sessionRoute<T>(Widget page) => PageRouteBuilder<T>(
  opaque: true,
  fullscreenDialog: true,
  transitionDuration: const Duration(milliseconds: 450),
  reverseTransitionDuration: const Duration(milliseconds: 300),
  pageBuilder: (_, _, _) => CupertinoTheme(
    data: const CupertinoThemeData(brightness: Brightness.dark),
    child: page,
  ),
  transitionsBuilder: (_, animation, _, child) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: child,
  ),
);

class SessionCloseButton extends StatelessWidget {
  const SessionCloseButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      icon: const Icon(CupertinoIcons.xmark),
      label: 'Close',
      onTap: onTap,
      width: HaloMetrics.barButtonSize,
      height: HaloMetrics.barButtonSize,
      iconSize: HaloMetrics.barButtonSize * HaloMetrics.barGlyphRatio,
      iconColor: const Color(0xE6FFFFFF),
      settings: HaloGlass.of(context),
      quality: HaloGlass.quality,
      useOwnLayer: true,
    );
  }
}

/// Durations to choose from, as a row of capsules.
class DurationPicker extends StatelessWidget {
  const DurationPicker({
    super.key,
    required this.minutes,
    required this.selected,
    required this.color,
    required this.onChanged,
  });

  final List<int> minutes;
  final int selected;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final m in minutes)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: ShapeDecoration(
                color: m == selected ? color : const Color(0x26FFFFFF),
                shape: const StadiumBorder(),
              ),
              child: Text(
                '$m min',
                style: TextStyle(
                  color: m == selected
                      ? const Color(0xFF000000)
                      : const Color(0xE6FFFFFF),
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
