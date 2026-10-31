import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../features/goals/presentation/goals_page.dart';
import '../../features/nutrition/presentation/nutrition_tab.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/today/presentation/edit_today_sheet.dart';
import '../../features/today/presentation/today_tab.dart';
import '../../features/workout/presentation/workout_tab.dart';
import '../../shared/widgets/account_glyph.dart';
import '../../shared/widgets/bar_items.dart';
import '../../shared/widgets/halo_page.dart';
import '../../shared/widgets/placeholder_page.dart';
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
///
/// Each tab has its own large-title controller, which owns that tab's scroll
/// controller, so the bar's small title follows whichever tab is showing. The
/// switch is instant, as iOS switches tabs: a cross-fade would hold two scroll
/// views on screen at once, and a quick tap back would hand one controller to
/// both.
class HaloTabsRoot extends StatefulWidget {
  const HaloTabsRoot({super.key});

  @override
  State<HaloTabsRoot> createState() => _HaloTabsRootState();
}

class _HaloTabsRootState extends State<HaloTabsRoot> {
  final Map<Object, GlassLargeTitleController> _titles = {
    for (final tab in HaloTab.values) tab: GlassLargeTitleController(),
  };

  @override
  void dispose() {
    for (final controller in _titles.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = HaloTabScope.of(context);

    // A boundary around the whole page: while a sheet is up the page dims
    // under it, and the boundary keeps that from re-rasterising its glass.
    return RepaintBoundary(child: _buildPage(context, controller));
  }

  Widget _buildPage(BuildContext context, HaloTabController controller) {
    final key = controller.tab;
    final title = _titles[key]!;

    return HaloPage(
      appBar: haloBar(
        context,
        title: controller.tab.title,
        largeTitleController: title,
        // The root has nothing behind it; the shell would otherwise draw a
        // chevron that does nothing.
        backButton: false,
        actions: [
          // Edit belongs to Today alone: it is the one tab whose content is
          // the user's own arrangement.
          if (controller.tab == HaloTab.today)
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
            onSettings: () => Navigator.of(context).push(SettingsPage.route()),
          ),
        ],
      ),
      body: KeyedSubtree(
        key: ValueKey(key),
        child: _buildBody(controller, title),
      ),
    );
  }

  Widget _buildBody(
    HaloTabController controller,
    GlassLargeTitleController title,
  ) {
    final tab = controller.tab;
    return switch (tab) {
      HaloTab.today => TodayTab(titleController: title),
      HaloTab.workout => WorkoutTab(titleController: title),
      HaloTab.nutrition => NutritionTab(titleController: title),
      HaloTab.plans => TabPlaceholder(
        titleController: title,
        icon: tab.glyph,
        title: tab.title,
        message: 'Your week of meals and training, adapted to you.',
      ),
      HaloTab.health => TabPlaceholder(
        titleController: title,
        icon: tab.glyph,
        title: tab.title,
        message: 'Every category, Health Age and Medical ID.',
      ),
    };
  }
}
