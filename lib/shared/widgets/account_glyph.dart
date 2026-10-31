import 'package:flutter/cupertino.dart';

import '../../app/halo_scope.dart';
import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_metrics.dart';
import '../../domain/avatar_preset.dart';
import '../../domain/body_profile.dart';

/// What the account button shows: the chosen avatar's emoji, or the person
/// glyph when none is chosen.
///
/// Listens to the profile itself, so a new avatar reaches the bar without the
/// page above having to know the profile exists.
class AccountGlyph extends StatefulWidget {
  const AccountGlyph({super.key});

  @override
  State<AccountGlyph> createState() => _AccountGlyphState();
}

class _AccountGlyphState extends State<AccountGlyph> {
  Stream<BodyProfile>? _profile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profile ??= HaloScope.preferencesOf(context).watchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BodyProfile>(
      stream: _profile,
      builder: (context, snapshot) {
        final preset = AvatarPreset.byName(snapshot.data?.avatar);
        if (preset != null) {
          return Text(
            preset.emoji,
            style: const TextStyle(
              fontSize: HaloMetrics.barButtonSize * 0.5,
              height: 1.1,
            ),
          );
        }
        return Icon(
          CupertinoIcons.person_crop_circle_fill,
          size: HaloMetrics.barButtonSize * HaloMetrics.accountGlyphRatio,
          color: HaloColors.labelOf(context),
        );
      },
    );
  }
}
