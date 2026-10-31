import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../data/activity/step_tracker.dart';
import '../../../data/transfer/data_transfer.dart';
import '../../../domain/app_theme_mode.dart';
import '../../../platform/android_permissions.dart';
import '../../../platform/files.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_alert.dart';
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
    final preferences = HaloScope.preferencesOf(context);
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
          const SizedBox(height: HaloMetrics.cardGap),
          GroupedCard(
            children: [
              _FlagRow(
                title: 'Haptic Feedback',
                watch: preferences.watchHaptics,
                set: preferences.setHaptics,
              ),
            ],
          ),
          const SizedBox(height: HaloMetrics.sectionTopGap),
          const GroupCaption('Workouts'),
          GroupedCard(
            children: [
              _FlagRow(
                title: 'Live Activity',
                watch: preferences.watchLiveActivity,
                set: preferences.setLiveActivity,
              ),
            ],
          ),
          const GroupCaption(
            'Shows the workout in progress on the Lock Screen and in the '
            'status bar, and in the Now Bar on Galaxy phones. Outdoor '
            'workouts on Android still show a small notification while they '
            'record the route.',
            footer: true,
          ),
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
          const GroupCaption('Data'),
          GroupedCard(
            children: [
              GroupedRow(title: 'Export Data', onTap: () => _export(context)),
              GroupedRow(title: 'Import Data', onTap: () => _import(context)),
            ],
          ),
          const GroupCaption(
            'CSV files a spreadsheet opens: steps, workouts and routes, '
            'sleep, food, water, weight, training, mindfulness and settings. '
            'Importing '
            'adds what is not already here.',
            footer: true,
          ),
          const SizedBox(height: HaloMetrics.sectionTopGap),
          const GroupedCard(
            children: [GroupedRow(title: 'Version', value: '1.0')],
          ),
        ],
      ),
    );
  }
}

Future<void> _export(BuildContext context) async {
  final transfer = DataTransfer(HaloScope.databaseOf(context));
  final now = DateTime.now();
  final folder =
      'Halo Export ${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
  try {
    final files = await transfer.export();
    final saved = await const SystemFiles().export(folder, files);
    if (!saved || !context.mounted) return;
    await showHaloAlert<void>(
      context,
      title: 'Data Exported',
      message: '${files.length} CSV files are in “$folder”.',
      actions: const [HaloAlertAction('OK', style: HaloAlertStyle.primary)],
    );
  } on Object catch (error) {
    if (!context.mounted) return;
    await showHaloAlert<void>(
      context,
      title: 'Couldn’t Export',
      message: '$error',
      actions: const [HaloAlertAction('OK', style: HaloAlertStyle.cancel)],
    );
  }
}

Future<void> _import(BuildContext context) async {
  final transfer = DataTransfer(HaloScope.databaseOf(context));
  try {
    final files = await const SystemFiles().import();
    if (files == null || files.isEmpty || !context.mounted) return;
    final go = await showHaloAlert<bool>(
      context,
      title: 'Import ${files.length} ${files.length == 1 ? 'File' : 'Files'}?',
      message:
          'Entries that are not already in Halo are added. Settings in the '
          'files replace the ones here.',
      actions: const [
        HaloAlertAction('Import', value: true, style: HaloAlertStyle.primary),
        HaloAlertAction('Cancel', value: false, style: HaloAlertStyle.cancel),
      ],
    );
    if (go != true) return;
    final added = await transfer.import(files);
    if (!context.mounted) return;
    await showHaloAlert<void>(
      context,
      title: 'Data Imported',
      message: added == 0
          ? 'Everything in these files was already here.'
          : '${Format.integer(added)} entries added.',
      actions: const [HaloAlertAction('OK', style: HaloAlertStyle.primary)],
    );
  } on Object catch (error) {
    if (!context.mounted) return;
    await showHaloAlert<void>(
      context,
      title: 'Couldn’t Import',
      message: '$error',
      actions: const [HaloAlertAction('OK', style: HaloAlertStyle.cancel)],
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

/// A setting that is on or off. As in iOS Settings, the switch is the only
/// target: the row around it does not highlight.
class _FlagRow extends StatefulWidget {
  const _FlagRow({required this.title, required this.watch, required this.set});

  final String title;
  final Stream<bool> Function() watch;
  final Future<void> Function(bool on) set;

  @override
  State<_FlagRow> createState() => _FlagRowState();
}

class _FlagRowState extends State<_FlagRow> {
  late final Stream<bool> _value = widget.watch();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _value,
      initialData: true,
      builder: (context, snapshot) {
        final on = snapshot.data ?? true;
        return GroupedRow(
          title: widget.title,
          trailing: GlassSwitch(
            value: on,
            onChanged: widget.set,
            activeColor: HaloColors.exercise.resolveFrom(context),
            settings: HaloGlass.of(context),
            quality: HaloGlass.quality,
            useOwnLayer: true,
            semanticLabel: widget.title,
          ),
        );
      },
    );
  }
}
