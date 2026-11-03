import 'package:flutter/widgets.dart';

/// The avatars a user can pick instead of their initials: an emoji on a
/// gradient of its own.
///
/// Stored by name, so reordering or adding presets never changes a choice
/// already made.
enum AvatarPreset {
  runner('🏃', Color(0xFFFF9F0A), Color(0xFFFF375F)),
  cyclist('🚴', Color(0xFF30D158), Color(0xFF0A84FF)),
  swimmer('🏊', Color(0xFF64D2FF), Color(0xFF0A84FF)),
  yoga('🧘', Color(0xFFBF5AF2), Color(0xFF5E5CE6)),
  lifter('🏋️', Color(0xFFFF453A), Color(0xFFFF9F0A)),
  mountain('⛰️', Color(0xFF63E6E2), Color(0xFF30D158)),
  fox('🦊', Color(0xFFFFD60A), Color(0xFFFF9F0A)),
  panda('🐼', Color(0xFF8E8E93), Color(0xFF3A3A3C)),
  lion('🦁', Color(0xFFFFD60A), Color(0xFFFF6482)),
  leaf('🌿', Color(0xFFA6FF00), Color(0xFF30D158)),
  bolt('⚡️', Color(0xFFFFD60A), Color(0xFFA6FF00)),
  moon('🌙', Color(0xFF5E5CE6), Color(0xFF1C1C1E)),
  // Sport.
  walker('🚶', Color(0xFF30D158), Color(0xFF63E6E2)),
  hiker('🥾', Color(0xFFAC8E68), Color(0xFF30D158)),
  climber('🧗', Color(0xFFFF9F0A), Color(0xFFAC8E68)),
  boxer('🥊', Color(0xFFFF453A), Color(0xFF1C1C1E)),
  tennis('🎾', Color(0xFFA6FF00), Color(0xFFFFD60A)),
  football('⚽️', Color(0xFF30D158), Color(0xFF1C1C1E)),
  basketball('🏀', Color(0xFFFF9F0A), Color(0xFFFF453A)),
  surfer('🏄', Color(0xFF64D2FF), Color(0xFF5E5CE6)),
  skier('⛷️', Color(0xFFE5E5EA), Color(0xFF64D2FF)),
  dancer('💃', Color(0xFFFF375F), Color(0xFFBF5AF2)),
  // Nature.
  sun('☀️', Color(0xFFFFD60A), Color(0xFFFF9F0A)),
  wave('🌊', Color(0xFF64D2FF), Color(0xFF0A84FF)),
  cactus('🌵', Color(0xFF30D158), Color(0xFFFFD60A)),
  flower('🌸', Color(0xFFFF6482), Color(0xFFBF5AF2)),
  tree('🌳', Color(0xFF30D158), Color(0xFF1C6B33)),
  star('⭐️', Color(0xFFFFD60A), Color(0xFF5E5CE6)),
  // Animals.
  cat('🐱', Color(0xFFFFD60A), Color(0xFFFF9F0A)),
  dog('🐶', Color(0xFFAC8E68), Color(0xFFFFD60A)),
  owl('🦉', Color(0xFF5E5CE6), Color(0xFFAC8E68)),
  turtle('🐢', Color(0xFF30D158), Color(0xFF63E6E2)),
  dolphin('🐬', Color(0xFF64D2FF), Color(0xFF5E5CE6)),
  tiger('🐯', Color(0xFFFF9F0A), Color(0xFF1C1C1E)),
  // Food.
  avocado('🥑', Color(0xFFA6FF00), Color(0xFF30D158)),
  apple('🍎', Color(0xFFFF453A), Color(0xFFFF9F0A));

  const AvatarPreset(this.emoji, this.top, this.bottom);

  final String emoji;

  /// The gradient behind the emoji, top to bottom.
  final Color top;
  final Color bottom;

  static AvatarPreset? byName(String? name) =>
      name == null ? null : AvatarPreset.values.asNameMap()[name];
}
