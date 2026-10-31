import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_glass.dart';
import '../../app/theme/halo_metrics.dart';
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
/// - **The keyboard does not resize the page**, so it cannot shove the floating
///   tab bar up the screen.
class HaloPage extends StatelessWidget {
  const HaloPage({
    super.key,
    required this.appBar,
    required this.body,
  });

  /// A `GlassAppBar.pinned` built with [haloBar].
  final PreferredSizeWidget appBar;

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return TransparentSystemBars(
      child: GlassScaffold(
        background: ColoredBox(
          color: HaloColors.background.resolveFrom(context),
        ),
        enableBackgroundSampling: false,
        statusBarStyle: GlassStatusBarStyle.none,
        topEdgeFade: true,
        bottomEdgeFade: true,
        bottomEdgeFadeExtent: 0,
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
/// [largeTitle] puts the title hard left at large-title size on the button's
/// own line, which is how the tab roots read. Pushed pages keep the centred
/// inline title.
GlassAppBar haloBar(
  BuildContext context, {
  required String title,
  bool largeTitle = false,
  bool backButton = true,
  List<GlassBarItem> leading = const [],
  List<GlassBarItem> actions = const [],
}) {
  final label = HaloColors.labelOf(context);

  return GlassAppBar.pinned(
    toolbarHeight: HaloMetrics.toolbarHeight,
    buttonSize: HaloMetrics.barButtonSize,
    buttonSettings: HaloGlass.of(context),
    backButton: backButton,
    leading: leading,
    leadingItemsSupplementBackButton: leading.isNotEmpty,
    centerTitle: !largeTitle,
    padding: const EdgeInsets.symmetric(
      horizontal: HaloMetrics.cardPadding,
    ),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: largeTitle
          ? TextStyle(
              color: label,
              fontSize: HaloMetrics.largeTitleSize,
              fontWeight: FontWeight.w700,
              letterSpacing: HaloMetrics.largeTitleTracking,
            )
          : TextStyle(
              color: label,
              fontSize: HaloMetrics.barTitleSize,
              fontWeight: FontWeight.w600,
            ),
    ),
    actions: actions,
  );
}
