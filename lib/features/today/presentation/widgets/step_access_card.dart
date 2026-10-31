import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

import '../../../../app/theme/halo_colors.dart';
import '../../../../data/activity/step_tracker.dart';
import '../../../../shared/widgets/halo_card.dart';

/// Asks for the step counter, from a button the user presses.
///
/// Shown only while access is missing. The rings cannot move without it, so
/// this sits directly under them rather than in a settings screen.
class StepAccessCard extends StatelessWidget {
  const StepAccessCard({
    super.key,
    required this.access,
    required this.onAllow,
  });

  final StepAccess access;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final unavailable = access == StepAccess.unavailable;
    final denied = access == StepAccess.denied;

    return HaloCard(
      child: Row(
        children: [
          Icon(
            Icons.directions_walk_rounded,
            size: 34,
            color: HaloColors.activity.resolveFrom(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unavailable ? 'No Step Counter' : 'Count Your Steps',
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unavailable
                      ? 'This phone has no step sensor, so the rings fill '
                          'from workouts only.'
                      : denied
                          ? 'Physical activity access is off. Turn it on in '
                              'Settings to fill your rings.'
                          : 'Halo uses your phone’s motion sensor to fill '
                              'your rings. Nothing leaves your phone.',
                  style: TextStyle(
                    color: HaloColors.secondaryLabelOf(context),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (!unavailable) ...[
            const SizedBox(width: 12),
            FilledCapsuleButton(
              label: denied ? 'Settings' : 'Allow',
              onTap: onAllow,
            ),
          ],
        ],
      ),
    );
  }
}
