import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../app/theme/halo_motion.dart';
import '../../../domain/notifications.dart';
import '../../../platform/android_permissions.dart';
import '../../../platform/notifications.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_page.dart';

/// Notifications: one switch for all of them, and each on its own, with its
/// time.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const NotificationsPage());

  /// How they are grouped on the page.
  static const groups = [
    ('Sleep', [NotificationKind.sleepSummary, NotificationKind.bedtime]),
    ('Activity', [NotificationKind.workout, NotificationKind.activity]),
    ('Progress', [NotificationKind.weekly, NotificationKind.weighIn]),
    (
      'Daily Habits',
      [
        NotificationKind.water,
        NotificationKind.meals,
        NotificationKind.mindful,
      ],
    ),
  ];

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with WidgetsBindingObserver {
  Stream<NotificationSettings>? _settings;
  PermissionState _permission = PermissionState.granted;
  bool _exact = true;

  static bool get _android => defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings ??= HaloScope.preferencesOf(context).watchNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from system Settings: the answers may have changed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  Future<void> _check() async {
    if (!_android) return;
    final permission = await AndroidPermissions.status(
      AndroidPermissions.postNotifications,
    );
    final exact = await const Reminders().exactAllowed();
    if (!mounted) return;
    setState(() {
      _permission = permission;
      _exact = exact;
    });
  }

  /// Saves, asking Android for permission the first time something is
  /// turned on.
  Future<void> _save(NotificationSettings next) async {
    await HaloScope.preferencesOf(context).setNotifications(next);
    if (!_android || !next.enabled) return;
    if (_permission == PermissionState.denied) {
      final answer = await AndroidPermissions.request(
        AndroidPermissions.postNotifications,
      );
      if (mounted) setState(() => _permission = answer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HaloPage(
      appBar: haloBar(context, title: 'Notifications'),
      body: StreamBuilder<NotificationSettings>(
        stream: _settings,
        initialData: const NotificationSettings(),
        builder: (context, snapshot) {
          final settings = snapshot.data ?? const NotificationSettings();
          final blocked =
              _android && _permission == PermissionState.permanentlyDenied;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              HaloMetrics.cardPadding,
              HaloMetrics.topInset(context),
              HaloMetrics.cardPadding,
              HaloMetrics.bottomInset(context),
            ),
            children: [
              GroupedCard(
                children: [
                  GroupedRow(
                    title: 'Allow Notifications',
                    trailing: _Switch(
                      value: settings.enabled,
                      label: 'Allow Notifications',
                      onChanged: (on) => _save(settings.copyWith(enabled: on)),
                    ),
                  ),
                ],
              ),
              GroupCaption(
                blocked
                    ? 'Notifications are off for Halo in Android’s settings. '
                          'Turn them on there to get any of these.'
                    : settings.enabled
                    ? 'Each one below can be turned off on its own. They '
                          'come only when they have something to say: none '
                          'once a goal is reached or a session is done.'
                    : 'Halo sends nothing. The workout in progress still '
                          'shows while it runs.',
                footer: true,
              ),
              if (blocked) ...[
                const SizedBox(height: 8),
                const GroupedCard(
                  children: [
                    GroupedRow(
                      title: 'Open Settings',
                      onTap: AndroidPermissions.openSettings,
                    ),
                  ],
                ),
              ],
              AnimatedOpacity(
                opacity: settings.enabled ? 1 : 0.4,
                duration: HaloMotion.of(context, HaloMotion.standardDuration),
                child: IgnorePointer(
                  ignoring: !settings.enabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (title, kinds)
                          in NotificationsPage.groups) ...[
                        const SizedBox(height: HaloMetrics.sectionTopGap),
                        GroupCaption(title),
                        GroupedCard(
                          children: [
                            for (final kind in kinds)
                              ..._rows(context, settings, kind),
                          ],
                        ),
                        GroupCaption(
                          kinds
                              .map((k) => '${k.title}: ${k.detail}')
                              .join('\n'),
                          footer: true,
                        ),
                      ],
                      if (_android && !_exact) ...[
                        const SizedBox(height: HaloMetrics.sectionTopGap),
                        GroupedCard(
                          children: [
                            GroupedRow(
                              title: 'Allow Exact Times',
                              onTap: () async {
                                await const Reminders().openExactSettings();
                              },
                            ),
                          ],
                        ),
                        const GroupCaption(
                          'Without it, Android may hold reminders back by a '
                          'few minutes to save battery.',
                          footer: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _rows(
    BuildContext context,
    NotificationSettings settings,
    NotificationKind kind,
  ) {
    final setting = settings.of(kind);
    void update(NotificationSetting next) =>
        unawaited(_save(settings.withKind(kind, next)));

    return [
      GroupedRow(
        title: kind.title,
        trailing: _Switch(
          value: setting.on,
          label: kind.title,
          onChanged: (on) => update(setting.copyWith(on: on)),
        ),
      ),
      if (setting.on)
        ...switch (kind.time) {
          NotificationTime.none => const <Widget>[],
          NotificationTime.daily => [
            _TimeRow(
              minutes: setting.minutes,
              onChanged: (m) => update(setting.copyWith(minutes: m)),
            ),
          ],
          NotificationTime.weekly => [
            GroupedRow(
              title: 'Day',
              value: _weekdays[setting.weekday - 1],
              editor: _WeekdayEditor(
                weekday: setting.weekday,
                onChanged: (d) => update(setting.copyWith(weekday: d)),
              ),
            ),
            _TimeRow(
              minutes: setting.minutes,
              onChanged: (m) => update(setting.copyWith(minutes: m)),
            ),
          ],
          NotificationTime.lead => [
            GroupedRow(
              title: 'Before Bedtime',
              value: '${setting.minutes} min',
              editor: _LeadEditor(
                minutes: setting.minutes,
                onChanged: (m) => update(setting.copyWith(minutes: m)),
              ),
            ),
          ],
        },
    ];
  }

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GlassSwitch(
    value: value,
    onChanged: onChanged,
    activeColor: HaloColors.exercise.resolveFrom(context),
    settings: HaloGlass.of(context),
    quality: HaloGlass.quality,
    useOwnLayer: true,
    semanticLabel: label,
  );
}

/// The time of day, opening a wheel beneath.
class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final m = minutes % (24 * 60);
    final label =
        '${(m ~/ 60).toString().padLeft(2, '0')}:'
        '${(m % 60).toString().padLeft(2, '0')}';
    // The wheel moves in fives; a time between them starts on the nearest.
    final rounded = (m / 5).round() * 5 % (24 * 60);
    return GroupedRow(
      title: 'Time',
      value: label,
      editor: RowWheel(
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          use24hFormat: true,
          minuteInterval: 5,
          initialDateTime: DateTime(2000, 1, 1, rounded ~/ 60, rounded % 60),
          onDateTimeChanged: (t) => onChanged(t.hour * 60 + t.minute),
        ),
      ),
    );
  }
}

class _WeekdayEditor extends StatelessWidget {
  const _WeekdayEditor({required this.weekday, required this.onChanged});

  final int weekday;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return RowWheel(
      child: CupertinoPicker(
        scrollController: FixedExtentScrollController(initialItem: weekday - 1),
        itemExtent: 36,
        onSelectedItemChanged: (i) => onChanged(i + 1),
        children: [
          for (final d in _NotificationsPageState._weekdays)
            Center(
              child: Text(
                d,
                style: TextStyle(
                  color: HaloColors.labelOf(context),
                  fontSize: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeadEditor extends StatelessWidget {
  const _LeadEditor({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  static const _options = [15, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final index = _options.indexOf(minutes);
    return RowWheel(
      child: CupertinoPicker(
        scrollController: FixedExtentScrollController(
          initialItem: index < 0 ? 1 : index,
        ),
        itemExtent: 36,
        onSelectedItemChanged: (i) => onChanged(_options[i]),
        children: [
          for (final m in _options)
            Center(
              child: Text(
                '$m min',
                style: TextStyle(
                  color: HaloColors.labelOf(context),
                  fontSize: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
