import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show ValueListenable, defaultTargetPlatform, TargetPlatform;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../features/workout/live/workout_controller.dart';
import '../../features/workout/live/workout_layer.dart';
import '../../features/workout/live/workout_pill.dart';
import '../theme/halo_colors.dart';
import '../theme/halo_glass.dart';
import '../theme/halo_metrics.dart';
import '../theme/halo_motion.dart';
import 'halo_tab.dart';
import 'halo_tab_controller.dart';

/// The tab bar, drawn once above the whole Navigator.
///
/// iOS keeps the tab bar on screen while you drill into a tab, and the
/// navigation bar's buttons morph between screens instead of sliding away. The
/// morph is `GlassNavigationShell` with `GlassAppBar.pinned`, which only works
/// for pushes onto the root Navigator, and a route pushed there covers
/// everything the Navigator draws. So the tab bar cannot live inside a page:
/// it sits above the Navigator, here, and pages slide underneath it.
///
/// Later this is also where the running-workout and sleep-session pills go,
/// as the tab bar's bottom accessory, expanding into full-screen layers above
/// everything, the way the Music player does.
class HaloChrome extends StatefulWidget {
  const HaloChrome({
    super.key,
    required this.child,
    required this.navigatorKey,
    required this.modalOnTop,
  });

  final Widget child;

  /// True while a sheet or dialog is presented. The bar slides off the bottom
  /// edge for it, the way a sheet covers the tab bar on iOS, and returns as
  /// the sheet goes down.
  ///
  /// Slid rather than faded: glass under an `Opacity` cannot fade, its
  /// backdrop pass renders fully or not at all.
  final ValueListenable<bool> modalOnTop;

  /// This widget is built in `CupertinoApp.builder`, above the Navigator, so
  /// `Navigator.of(context)` finds nothing from here. Tapping a tab while a
  /// page is pushed has to pop back to the root, and this key is the handle.
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<HaloChrome> createState() => _HaloChromeState();
}

class _HaloChromeState extends State<HaloChrome> with WidgetsBindingObserver {
  /// Measures the workout pill, so the live workout grows out of it and
  /// shrinks back into it.
  final GlobalKey _pillKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Android's back button, caught before the Navigator sees it.
  ///
  /// The live workout is a layer above the Navigator, not a route, so neither
  /// `PopScope` nor a back-button listener can reach it. Registered after the
  /// Navigator's observer, this one is asked first: with the workout up, back
  /// minimises it rather than popping the page underneath.
  @override
  Future<bool> didPopRoute() async {
    final workouts = WorkoutScope.read(context);
    if (!workouts.expanded) return false;
    workouts.minimize();
    return true;
  }

  Rect? _pillRect() {
    final box = _pillKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _popToRoot() {
    final navigator = widget.navigatorKey.currentState;
    if (navigator?.canPop() ?? false) {
      navigator!.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The chrome keeps an Overlay of its own: it sits above the Navigator and
    // so above the Navigator's Overlay, and anything the bar or its accessory
    // shows over itself asks for `Overlay.of(context)`.
    //
    // The controller is read inside the entry's builder: an OverlayEntry does
    // not rebuild with its parent, so a dependency taken out here would leave
    // the tab bar frozen on its first state.
    return Overlay(initialEntries: [OverlayEntry(builder: _buildLayers)]);
  }

  Widget _buildLayers(BuildContext context) {
    final controller = HaloTabScope.of(context);
    final workouts = WorkoutScope.of(context);

    return Stack(
      children: [
        // What shows around the page when a sheet scales it back: black, in
        // both appearances, as on iOS. Nothing else ever uncovers it.
        const Positioned.fill(child: ColoredBox(color: Color(0xFF000000))),
        Positioned.fill(child: widget.child),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          // What `GlassScaffold` would do for its own bottom bar, done here
          // because the bar lives here: clear Android's navigation bar, and pin
          // the bar's quality independently of the page behind it.
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: defaultTargetPlatform == TargetPlatform.android,
            child: GlassIsolationScope(
              isolated: true,
              defaultQuality: HaloGlass.quality,
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.modalOnTop,
                // The bar is built once and handed through, so presenting a
                // sheet animates its position without rebuilding it.
                builder: (context, covered, bar) => IgnorePointer(
                  ignoring: covered,
                  child: AnimatedSlide(
                    offset: covered ? const Offset(0, 1.3) : Offset.zero,
                    duration: HaloMotion.of(
                      context,
                      HaloMotion.standardDuration,
                    ),
                    curve: HaloMotion.standardCurve,
                    child: bar,
                  ),
                ),
                // The bar's indicator spring runs on its own; without a
                // boundary every frame of it would mark the whole app dirty.
                child: RepaintBoundary(
                  child: _buildTabBar(context, controller, workouts),
                ),
              ),
            ),
          ),
        ),
        // Above the tab bar, because the workout covers the chrome it grows
        // out of. Nothing inside the Navigator can paint over the chrome.
        Positioned.fill(
          child: WorkoutLayer(controller: workouts, pillRect: _pillRect),
        ),
      ],
    );
  }

  Widget _buildTabBar(
    BuildContext context,
    HaloTabController controller,
    WorkoutController workouts,
  ) {
    final session = workouts.session;
    final accent = HaloColors.accent.resolveFrom(context);
    final label = HaloColors.labelOf(context);

    return GlassTabBar.bottom(
      selectedIndex: controller.tab.index,
      onTabSelected: (index) {
        final next = HaloTab.values[index];
        // A tab tap always returns to the root of the stack first, or the bar
        // would change the tab underneath a page that stays on top of it.
        _popToRoot();
        controller.tab = next;
      },
      // The workout in progress sits above the bar, the way Music keeps its
      // mini player there. The bar animates the slot in and out.
      // Inset like the bar itself, so the pill is exactly as wide as the tab
      // capsule under it; the bottom layout lays the accessory edge to edge.
      bottomAccessory: session == null
          ? null
          : Transform.translate(
              // The bar's own top padding already opens a gap above the
              // capsule; nudged down so the pill sits close over it, as
              // Music's mini player does.
              offset: const Offset(0, HaloMetrics.accessoryDrop),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: HaloMetrics.tabBarHorizontalPadding,
                ),
                child: WorkoutPill(
                  key: _pillKey,
                  session: session,
                  height: HaloMetrics.accessoryHeight,
                  onOpen: workouts.expand,
                ),
              ),
            ),
      bottomAccessoryHeight: HaloMetrics.accessoryHeight,
      // Hidden while the keyboard is up, so it never rides up into the field.
      bottomAccessoryEnabled:
          session != null && MediaQuery.viewInsetsOf(context).bottom == 0,
      barHeight: HaloMetrics.tabBarHeight,
      horizontalPadding: HaloMetrics.tabBarHorizontalPadding,
      verticalPadding: HaloMetrics.tabBarVerticalPadding,
      spacing: HaloMetrics.tabBarSpacing,
      iconSize: HaloMetrics.tabIconSize,
      labelFontSize: HaloMetrics.tabLabelSize,
      iconLabelSpacing: HaloMetrics.tabIconLabelSpacing,
      // The active tab takes the accent, glyph and label both, as in Music and
      // Clock. The rest stay in the label colour.
      selectedIconColor: accent,
      selectedLabelColor: accent,
      unselectedIconColor: label,
      unselectedLabelColor: label,
      // The indicator as Music draws it.
      indicatorColor: label.withValues(alpha: 0.20),
      settings: HaloGlass.tabBar(context),
      quality: HaloGlass.quality,
      interactionBehavior: GlassInteractionBehavior.full,
      tabs: [
        for (final tab in HaloTab.values)
          GlassTab(label: tab.title, icon: tab.glyph, activeIcon: tab.glyph),
      ],
    );
  }
}
