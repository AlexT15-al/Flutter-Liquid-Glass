import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_motion.dart';
import '../../../domain/avatar_preset.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_sheet.dart';
import '../../../shared/widgets/profile_avatar.dart';

/// Lets the user pick an avatar, or none, which keeps the initials.
///
/// Resolves to the chosen preset's name, to `''` for none, or to null when
/// dismissed without choosing.
Future<String?> showAvatarSheet(
  BuildContext context, {
  required String? name,
  required String? current,
}) {
  return showHaloSheet<String>(
    context,
    builder: (context, controller) => _AvatarSheet(
      controller: controller,
      name: name,
      initial: current,
    ),
  );
}

class _AvatarSheet extends StatefulWidget {
  const _AvatarSheet({
    required this.controller,
    required this.name,
    required this.initial,
  });

  final ScrollController controller;
  final String? name;
  final String? initial;

  @override
  State<_AvatarSheet> createState() => _AvatarSheetState();
}

class _AvatarSheetState extends State<_AvatarSheet> {
  /// Null is "none": the initials.
  late AvatarPreset? _selected = AvatarPreset.byName(widget.initial);

  void _select(AvatarPreset? preset) {
    HapticFeedback.selectionClick();
    setState(() => _selected = preset);
  }

  @override
  Widget build(BuildContext context) {
    final options = <AvatarPreset?>[null, ...AvatarPreset.values];

    return HaloSheet(
      controller: widget.controller,
      header: HaloSheetHeader(
        title: 'Avatar',
        leading: SheetButton.close(context),
        trailing: SheetConfirmButton(
          onTap: () => Navigator.of(context).pop(_selected?.name ?? ''),
        ),
      ),
      children: [
        const SizedBox(height: 8),
        // The choice, large, so the grid below is a preview of it.
        Center(
          child: AnimatedSwitcher(
            duration: HaloMotion.of(context, HaloMotion.controlSwapDuration),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween(begin: 0.85, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: ProfileAvatar(
              key: ValueKey(_selected),
              name: widget.name,
              preset: _selected,
              size: 120,
            ),
          ),
        ),
        const SizedBox(height: 24),
        HaloCard(
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            children: [
              for (final option in options)
                _Option(
                  selected: option == _selected,
                  onTap: () => _select(option),
                  label: option?.name ?? 'Initials',
                  child: ProfileAvatar(
                    name: widget.name,
                    preset: option,
                    size: 62,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One choice in the grid, ringed in the accent when selected.
class _Option extends StatelessWidget {
  const _Option({
    required this.selected,
    required this.onTap,
    required this.label,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: HaloMotion.of(context, HaloMotion.controlSwapDuration),
          curve: HaloMotion.standardCurve,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 3,
              color: selected
                  ? HaloColors.accent.resolveFrom(context)
                  : const Color(0x00000000),
            ),
          ),
          child: FittedBox(child: child),
        ),
      ),
    );
  }
}
