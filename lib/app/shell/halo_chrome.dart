import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/halo_colors.dart';
import '../theme/halo_glass.dart';
import '../theme/halo_metrics.dart';
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
  });

  final Widget child;

  /// This widget is built in `CupertinoApp.builder`, above the Navigator, so
  /// `Navigator.of(context)` finds nothing from here. Tapping a tab while a
  /// page is pushed has to pop back to the root, and this key is the handle.
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<HaloChrome> createState() => _HaloChromeState();
}

class _HaloChromeState extends State<HaloChrome> {
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchFocusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // A focus callback runs outside a build, so the scope is read without
    // registering a dependency.
    HaloTabScope.read(context).searchFieldFocused = _searchFocusNode.hasFocus;
  }

  void _popToRoot() {
    final navigator = widget.navigatorKey.currentState;
    if (navigator?.canPop() ?? false) {
      navigator!.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The chrome needs an Overlay of its own. The search field lives in the tab
    // bar, above the Navigator and therefore above the Navigator's Overlay, and
    // text selection asks for `Overlay.of(context)` on the first keystroke.
    //
    // The controller is read inside the entry's builder: an OverlayEntry does
    // not rebuild with its parent, so a dependency taken out here would leave
    // the tab bar frozen on its first state.
    return Overlay(
      initialEntries: [
        OverlayEntry(builder: _buildLayers),
      ],
    );
  }

  Widget _buildLayers(BuildContext context) {
    final controller = HaloTabScope.of(context);

    return Stack(
      children: [
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
              // The bar's indicator spring runs on its own; without a boundary
              // every frame of it would mark the whole app dirty.
              child: RepaintBoundary(child: _buildTabBar(context, controller)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context, HaloTabController controller) {
    final accent = HaloColors.accent.resolveFrom(context);
    final label = HaloColors.labelOf(context);

    return GlassTabBar.searchable(
      isSearchActive: controller.isSearching,
      selectedIndex: controller.tab.index,
      onTabSelected: (index) {
        final next = HaloTab.values[index];
        // A tab tap always returns to the root of the stack first, or the bar
        // would change the tab underneath a page that stays on top of it.
        _popToRoot();
        controller.tab = next;
      },
      barHeight: HaloMetrics.tabBarHeight,
      searchBarHeight: HaloMetrics.searchBarHeight,
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
      indicatorColor: label.withValues(alpha: 0.12),
      settings: HaloGlass.of(context),
      quality: HaloGlass.quality,
      interactionBehavior: GlassInteractionBehavior.full,
      searchConfig: GlassSearchBarConfig(
        focusNode: _searchFocusNode,
        hintText: 'Search',
        showsCancelButton: true,
        textInputAction: TextInputAction.search,
        searchIconColor: label,
        onSearchToggle: (active) {
          // Search is a tab body, so a page pushed over it would hide the
          // results. Opening it returns to the root first.
          if (active) _popToRoot();
          controller.isSearching = active;
        },
        onChanged: (value) => controller.query = value,
        onSearchFocusChanged: (focused) =>
            controller.searchFieldFocused = focused,
        // The × leaves search altogether. Without this the package only
        // unfocuses, and search stays open behind a dropped keyboard.
        onCancelTap: () => controller.isSearching = false,
        // Collapsed, the tab capsule shows the active tab's glyph.
        collapsedLogoBuilder: (context) => Center(
          child: IconTheme(
            data: IconThemeData(color: label, size: HaloMetrics.tabIconSize),
            child: controller.tab.glyph,
          ),
        ),
      ),
      tabs: [
        for (final tab in HaloTab.values)
          GlassTab(
            label: tab.title,
            icon: tab.glyph,
            activeIcon: tab.glyph,
          ),
      ],
    );
  }
}
