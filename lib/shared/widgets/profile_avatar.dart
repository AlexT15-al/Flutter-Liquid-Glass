import 'package:flutter/cupertino.dart';

import '../../app/theme/halo_colors.dart';
import '../../domain/avatar_preset.dart';

/// The user's avatar: a chosen preset, or else their initials, or else a
/// person glyph, each on a gradient circle.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    required this.size,
    this.preset,
  });

  final String? name;
  final AvatarPreset? preset;
  final double size;

  static String initialsOf(String? name) {
    final words = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    final first = words.first.characters.first;
    final last = words.length > 1 ? words.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final preset = this.preset;
    if (preset != null) {
      return _Circle(
        size: size,
        top: preset.top,
        bottom: preset.bottom,
        child: Text(
          preset.emoji,
          style: TextStyle(fontSize: size * 0.5, height: 1.1),
        ),
      );
    }

    final initials = initialsOf(name);
    final accent = HaloColors.accent.resolveFrom(context);
    final ink = HaloColors.onAccent.resolveFrom(context);

    return _Circle(
      size: size,
      top: accent,
      bottom: Color.lerp(accent, const Color(0xFF000000), 0.35)!,
      child: initials.isEmpty
          ? Icon(CupertinoIcons.person_fill, size: size * 0.5, color: ink)
          : Text(
              initials,
              style: TextStyle(
                color: ink,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({
    required this.size,
    required this.top,
    required this.bottom,
    required this.child,
  });

  final double size;
  final Color top;
  final Color bottom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
