import 'package:flutter/cupertino.dart';

import '../../../../app/theme/halo_colors.dart';
import '../../../../shared/widgets/halo_card.dart';

/// A half-width tile for one metric, in the shape Health draws its summary
/// tiles: the category's glyph and name in the category colour at the top,
/// the value large at the bottom, an optional chart between.
///
/// A metric with nothing recorded shows "No Data" in place of the value, which
/// is what Health says rather than a zero that would claim a measurement.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.value,
    this.unit,
    this.caption,
    this.chart,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;

  /// Null shows "No Data".
  final String? value;
  final String? unit;

  /// A short line above the value, such as "Today" or "Last night".
  final String? caption;

  final Widget? chart;
  final VoidCallback? onTap;

  static const double height = 156;

  @override
  Widget build(BuildContext context) {
    return HaloCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: SizedBox(
        height: height - 26,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 13,
                  color: HaloColors.tertiaryLabelOf(context),
                ),
              ],
            ),
            const Spacer(),
            if (chart != null && value != null) ...[
              chart!,
              const SizedBox(height: 10),
            ],
            if (caption != null)
              Text(
                caption!,
                style: TextStyle(
                  color: HaloColors.secondaryLabelOf(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            _Value(value: value, unit: unit),
          ],
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.value, required this.unit});

  final String? value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    if (value == null) {
      return Text(
        'No Data',
        style: TextStyle(
          color: HaloColors.secondaryLabelOf(context),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          if (unit != null)
            TextSpan(
              text: ' $unit',
              style: TextStyle(
                color: HaloColors.secondaryLabelOf(context),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    );
  }
}
