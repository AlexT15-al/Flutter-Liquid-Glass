import 'package:flutter/cupertino.dart';

import '../../features/goals/presentation/goals_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/today/presentation/edit_today_sheet.dart';
import '../../features/today/presentation/today_tab.dart';
import '../../shared/widgets/account_glyph.dart';
import '../../shared/widgets/bar_items.dart';
import '../../shared/widgets/halo_page.dart';
import '../../shared/widgets/placeholder_page.dart';
import '../theme/halo_motion.dart';
import 'halo_tab.dart';
import 'halo_tab_controller.dart';

/// The root route: one page holding all four tabs.
///
/// The tab bar is not here. It lives in `HaloChrome`, above the Navigator, so
/// a pushed route slides under it instead of covering it. What is left here is
/// the tab bodies and the per-tab navigation bar.
///
/// Switching tabs is a `setState`, not a route change: nothing is pushed, so
/// there is nothing for the navigation shell to hoist. Only drilling into a
/// tab pushes.
class HaloTabsRoot extends StatelessWidget {
  const HaloTabsRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = HaloTabScope.of(context);

    // A boundary around the whole page, for the sheets' sake: while one is up
    // the route holds this page on screen and animates it back in scale, and
    // without a boundary that transform would re-rasterise every glass surface
    // on it, every frame. With one, the compositor moves a texture.
    return RepaintBoundary(child: _buildPage(context, controller));
  }

  Widget _buildPage(BuildContext context, HaloTabController controller) {
    return HaloPage(
      appBar: haloBar(
        context,
        title: controller.isSearching ? 'Search' : controller.tab.title,
        largeTitle: true,
        // The root has nothing behind it; the shell would otherwise draw a
        // chevron that does nothing.
        backButton: false,
        actions: [
          // Edit belongs to Today alone: it is the one tab whose content is
          // the user's own arrangement.
          if (controller.tab == HaloTab.today && !controller.isSearching)
            editBarItem(
              editing: false,
              onTap: () => showEditTodaySheet(context),
            ),
          accountBarItem(
            context,
            glyph: const AccountGlyph(),
            onProfile: () => Navigator.of(context).push(ProfilePage.route()),
            onGoals: () => Navigator.of(context).push(GoalsPage.route()),
            onAwards: () =>
                Navigator.of(context).push(PlaceholderPage.route('Awards')),
            onSettings: () =>
                Navigator.of(context).push(SettingsPage.route()),
          ),
        ],
      ),
      body: GestureDetector(
        // Tapping the page dismisses the search keyboard, as it does on iOS.
        onTap: () {
          if (controller.searchFieldFocused) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: AnimatedSwitcher(
          duration: HaloMotion.of(context, HaloMotion.tabSwitchDuration),
          // A cross-fade, not a slide: iOS tab bars do not move content
          // sideways, and the indicator is the motion the eye follows.
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: _buildBody(controller),
        ),
      ),
    );
  }

  /// The active tab's content, keyed so the switcher treats a tab change as a
  /// swap rather than an update of the same child.
  Widget _buildBody(HaloTabController controller) {
    if (controller.isSearching) {
      return const TabPlaceholder(
        key: ValueKey('search'),
        icon: Icon(CupertinoIcons.search),
        title: 'Search',
        message: 'Metrics, workouts, foods and settings.',
      );
    }

    final tab = controller.tab;
    if (tab == HaloTab.today) {
      return const TodayTab(key: ValueKey(HaloTab.today));
    }
    return TabPlaceholder(
      key: ValueKey(tab),
      icon: tab.glyph,
      title: tab.title,
      message: switch (tab) {
        HaloTab.today => 'Your rings, readiness and the day at a glance.',
        HaloTab.workout => 'Start, track and review your workouts.',
        HaloTab.sleep => 'Last night, your schedule and smart alarm.',
        HaloTab.health => 'Every category, Health Age and Medical ID.',
      },
    );
  }
}
