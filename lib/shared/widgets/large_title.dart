import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_metrics.dart';

/// The top of a tab's scroll view: room for the bar, then the iOS large title.
///
/// The title is part of the content and scrolls away with it. As it goes, the
/// same [controller] fades the small title into the navigation bar, and the
/// bar's scroll edge effect frosts the content passing underneath; pulled down
/// past the top, the large title stretches, as UIKit's does.
///
/// The scroll view has to scroll on `controller.scrollController`, which is
/// how the controller knows how far the title has gone.
List<Widget> largeTitleSlivers(
  BuildContext context, {
  required String title,
  required GlassLargeTitleController controller,
}) {
  return [
    SliverToBoxAdapter(
      child: SizedBox(
        height: MediaQuery.paddingOf(context).top + HaloMetrics.toolbarHeight,
      ),
    ),
    GlassLargeTitle(
      text: title,
      controller: controller,
      color: HaloColors.labelOf(context),
      fontSize: HaloMetrics.largeTitleSize,
      letterSpacing: HaloMetrics.largeTitleTracking,
      padding: const EdgeInsetsDirectional.fromSTEB(
        HaloMetrics.pagePadding,
        2,
        HaloMetrics.pagePadding,
        12,
      ),
    ),
  ];
}
