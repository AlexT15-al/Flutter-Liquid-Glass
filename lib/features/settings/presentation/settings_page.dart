import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../data/activity/step_tracker.dart';
import '../../../domain/app_theme_mode.dart';
import '../../../platform/android_permissions.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_page.dart';
import '../../goals/presentation/goals_page.dart';
import '../../profile/presentation/profile_page.dart';

/// Settings, reached from the account menu.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const SettingsPage());

  @override
  Widget build(BuildContext context) {
    return HaloPage(
      appBar: haloBar(context, title: 'Settings'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          HaloMetrics.cardPadding,
          HaloMetrics.topInset(context),
          HaloMetrics.cardPadding,
          HaloMetrics.bottomInset(context),
        ),
        children: [
          const GroupCaption('Appearance'),
          const _AppearanceCard(),
          const SizedBox(height: HaloMetrics.sectionTopGap),
          const GroupCaption('You'),
          GroupedCard(
            children: [
              GroupedRow(
                title: 'Profile',
                onTap: () => Navigator.of(context).push(ProfilePage.route()),
              ),
              GroupedRow(
                title: 'Goals',
                onTap: () => Navigator.of(context).push(GoalsPage.route()),
              ),
            ],
          ),
          const SizedBox(height: HaloMetrics.sectionTopGap),
          const GroupCaption('Privacy'),
          const _MotionAccessCard(),
          const GroupCaption(
            'Everything Halo records stays on this phone. Nothing is sent '
            'anywhere.',
            footer: true,
          ),
          const SizedBox(height: HaloMetrics.sectionTopGap),
          const GroupedCard(
            children: [
              GroupedRow(title: 'Version', value: '1.0'),
            ],
          ),
        ],
      ),
    );
  }
}

/// System, Light or Dark.
///
/// A segmented control in a solid card, which is the one place glass controls
/// may sit on a card: the pill only turns to glass while it moves.
class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final preferences = HaloScope.preferencesOf(context);

    return StreamBuilder<AppThemeMode>(
      stream: preferences.watchThemeMode(),
      initialData: AppThemeMode.system,
      builder: (context, snapshot) {
        final mode = snapshot.data ?? AppThemeMode.system;
        return HaloCard(
          padding: const EdgeInsets.all(12),
          child: GlassSegmentedControl(
            segments: [
              for (final value in AppThemeMode.values)
                GlassSegment(label: value.label),
            ],
            selectedIndex: mode.index,
            // Writes the preference and nothing else. The app follows the same
            // stream, so the whole tree changes from one write.
            onSegmentSelected: (index) =>
                preferences.setThemeMode(AppThemeMode.values[index]),
            height: 40,
            borderRadius: 20,
            settings: HaloGlass.of(context),
            quality: HaloGlass.quality,
            useOwnLayer: true,
            // The control replaces the ambient text style, so it is handed
            // the app's own, font family included.
            selectedTextStyle: DefaultTextStyle.of(context).style.copyWith(
              color: HaloColors.labelOf(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            unselectedTextStyle: DefaultTextStyle.of(context).style.copyWith(
              color: HaloColors.secondaryLabelOf(context),
              fontSize: 15,
            ),
          ),
        );
      },
    );
  }
}

/// Whether the step counter is allowed, and a way to change it.
class _MotionAccessCard extends StatelessWidget {
  const _MotionAccessCard();

  @override
  Widget build(BuildContext context) {
    final steps = HaloScope.stepsOf(context);
    final android = defaultTargetPlatform == TargetPlatform.android;

    return ValueListenableBuilder<StepAccess>(
      valueListenable: steps.access,
      builder: (context, access, _) => GroupedCard(
        children: [
          GroupedRow(
            title: 'Physical Activity',
            value: switch (access) {
              StepAccess.granted => 'Allowed',
              StepAccess.unavailable => 'No Sensor',
              _ => 'Off',
            },
            // Granted access can only be withdrawn in system Settings, so
            // the row goes there; otherwise it asks.
            onTap: access == StepAccess.unavailable
                ? null
                : access == StepAccess.granted && android
                    ? AndroidPermissions.openSettings
                    : steps.requestAccess,
          ),
        ],
      ),
    );
  }
}
