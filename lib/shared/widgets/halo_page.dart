import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_glass.dart';
import '../../app/shell/modal_route_observer.dart';
import '../../app/theme/halo_metrics.dart';
import '../../app/theme/halo_motion.dart';
import 'bar_items.dart';
import 'transparent_system_bars.dart';

/// Every screen's scaffold, configured once.
///
/// A `GlassScaffold` with the same choices on every page, so no screen can
/// drift from the others:
///
/// - **An opaque background of its own.** A route slides over the page behind
///   it, and without one the previous screen shows through the push.
/// - **No background sampling.** The page behind the glass is one flat colour;
///   capturing it into a texture teaches the shader nothing and costs a
///   capture per frame.
/// - **System bars owned by [TransparentSystemBars]**, not the scaffold.
/// - **The scroll edge effect** under the bar, and only there.
/// - **The keyboard does not resize the page**, so it cannot shove the floating
///   tab bar up the screen.
class HaloPage extends StatelessWidget {
  const HaloPage({super.key, required this.appBar, required this.body});

  /// A `GlassAppBar.pinned` built with [haloBar].
  final PreferredSizeWidget appBar;

  final Widget body;

  /// How dark the page goes under a sheet: enough to set the sheet apart in
  /// light mode, where page and sheet share a colour, without hiding what the
  /// sheet was opened from.
  static const double _sheetDim = 0.22;

  @override
  Widget build(BuildContext context) {
    final modalOnTop = ModalPresentationScope.maybeOf(context);
    final page = _buildScaffold(context);
    if (modalOnTop == null) return page;

    return Stack(
      children: [
        page,
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder<bool>(
              valueListenable: modalOnTop,
              builder: (context, covered, _) => AnimatedOpacity(
                opacity: covered ? 1 : 0,
                duration: HaloMotion.of(context, HaloMotion.standardDuration),
                curve: HaloMotion.standardCurve,
                child: const ColoredBox(
                  color: Color.fromRGBO(0, 0, 0, _sheetDim),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return TransparentSystemBars(
      child: GlassScaffold(
        background: ColoredBox(
          color: HaloColors.background.resolveFrom(context),
        ),
        enableBackgroundSampling: false,
        statusBarStyle: GlassStatusBarStyle.none,
        // The scroll edge effect at the top only: content dissolves into the
        // page as it passes under the bar. Nothing at the bottom; the floating
        // tab bar's own glass is enough there.
        topEdgeFade: true,
        bottomEdgeFade: false,
        resizeToAvoidBottomInset: false,
        appBar: appBar,
        body: body,
      ),
    );
  }
}

/// A pinned navigation bar with Halo's metrics.
///
/// Every bar in the app goes through here so every one passes the 48pt
/// `buttonSize` and the iOS 27 material for its hoisted buttons. A bar built
/// by hand that forgets either goes back to the package's 44pt defaults and
/// visibly resizes its buttons at the moment of a push.
///
/// With [largeTitleController] the bar's title stays hidden until the page's
/// large title has scrolled away, then fades in: the tab roots, which carry a
/// `GlassLargeTitle` in their content. Without one the small title shows from
/// the start, as on a pushed page.
GlassAppBar haloBar(
  BuildContext context, {
  required String title,
  GlassLargeTitleController? largeTitleController,
  bool backButton = true,
  List<GlassBarItem> leading = const [],
  List<GlassBarItem> actions = const [],
}) {
  final label = HaloColors.labelOf(context);
  // The package draws its automatic back chevron at a fixed 22pt, which in a
  // 48pt circle looks lost. So the bar never uses the automatic one: a page
  // that can go back gets this item instead, the same 48pt glass circle with a
  // chevron sized to it, matched across routes by its id like any other item.
  final canGoBack =
      backButton && (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);

  return GlassAppBar.pinned(
    toolbarHeight: HaloMetrics.toolbarHeight,
    buttonSize: HaloMetrics.barButtonSize,
    buttonSettings: HaloGlass.of(context),
    backButton: false,
    leading: [
      if (canGoBack)
        GlassBarItem.icon(
          id: BarItemIds.back,
          label: 'Back',
          background: GlassBarItemBackground.separate,
          icon: const Icon(
            CupertinoIcons.chevron_back,
            size: HaloMetrics.barButtonSize * HaloMetrics.backGlyphRatio,
          ),
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ...leading,
    ],
    largeTitleController: largeTitleController,
    padding: const EdgeInsets.symmetric(horizontal: HaloMetrics.cardPadding),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: label,
        fontSize: HaloMetrics.barTitleSize,
        fontWeight: FontWeight.w600,
      ),
    ),
    actions: actions,
  );
}
